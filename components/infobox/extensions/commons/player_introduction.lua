---
-- @Liquipedia
-- wiki=commons
-- page=Module:PlayerIntroduction
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local SHOULD_QUERY_KEYWORD = 'query'
local DEFAULT_DATAPOINT_LEAVE_DATE = '2999-01-01'
local TRANSFER_STATUS_FORMER = 'former'
local TRANSFER_STATUS_LOAN = 'loan'
local TRANSFER_STATUS_CURRENT = 'current'
local SKIP_ROLE = 'skip'

--- @class PlayerIntroduction
local PlayerIntroduction = Class.new(function(self, ...) self:init(...) end)

---@deprecated
--- only for legacy support
function PlayerIntroduction._main(args)
	return PlayerIntroduction.run(args)
end

---@deprecated
--- only for legacy support
function PlayerIntroduction.main(frame)
	return PlayerIntroduction.run(Arguments.getArgs(frame))
end

-- template entry point
function PlayerIntroduction.templatePlayerIntroduction(frame)
	return PlayerIntroduction.run(Arguments.getArgs(frame))
end

-- module entry point
function PlayerIntroduction.run(args)
	return PlayerIntroduction(args):create()
end

--- Init function for PlayerIntroduction
---@param args {
---	[1]: string?,
---	player: string?,
---	playerInfo: string?,
---	birthdate: string?,
---	deathdate: string?,
---	defaultGame: string?,
---	faction: string?,
---	faction2: string?,
---	faction3: string?,
---	firstname: string?,
---	lastname: string?,
---	freetext: string?,
---	game: string?,
---	id: string?,
---	idAudio: string?,
---	idIPA: string?,
---	name: string?,
---	nationality: string?,
---	nationality2: string?,
---	nationality3: string?,
---	role: string?,
---	role2: string?,
---	status: string?,
---	subtext: string?,
---	team: string?,
---	team2: string?,
---	type: string?,
---	transferquery: 'datapoint'?,
---	convert_role: boolean?,
---	show_role: boolean?,
---	formernameX: string?,
---	akaX: string?,
---}
---@return self
function PlayerIntroduction:init(args)
	self.player = mw.ext.TeamLiquidIntegration.resolve_redirect(
		args.player or args[1] or mw.title.getCurrentTitle().text
	):gsub(' ', '_')

	local playerInfo = {}
	if Logic.emptyOr(args.playerInfo, SHOULD_QUERY_KEYWORD) == SHOULD_QUERY_KEYWORD then
		playerInfo = self:_playerQuery()
	end

	self:_parsePlayerInfo(args, playerInfo)

	self:_readTransferData(args.transferquery)

	self:_roleAdjusts(args)

	self.options = {
		showRole = Logic.readBool(args.show_role),
		showFaction = Logic.readBool(args.show_faction),
	}

	return self
end

function PlayerIntroduction:_playerQuery()
	local queryData = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. self.player .. ']]',
		query = 'id, name, localizedname, type, nationality, nationality, nationality2, nationality3, '
			.. 'birthdate, deathdate, status, extradata, teampagename',
	})

	if type(queryData[1]) == 'table' then
		return queryData[1]
	end

	return {}
end

---@param args table
---@param playerInfo table
---@return nil
function PlayerIntroduction:_parsePlayerInfo(args, playerInfo)
	playerInfo.extradata = playerInfo.extradata or {}

	local role = (args.role or playerInfo.extradata.role or ''):lower()

	local personType = Logic.emptyOr(args.type, playerInfo.type, 'player'):lower()
	if personType ~= 'player' and String.isNotEmpty(role) then
		personType = role
	end

	local name = args.name or playerInfo.name

	local nameArray = String.isNotEmpty(name)
		and mw.text.split(name, ' ')
		or {}

	local function readNames(prefix)
		return Array.extractValues(Table.filter(args, function(entry) return entry:find('^' .. prefix .. '%d+$') end))
	end

	self.playerInfo = {
		team = args.team or playerInfo.teampagename,
		team2 = args.team2 or playerInfo.extradata.team2,
		name = name,
		status = Logic.emptyOr(args.status, playerInfo.status, 'active'):lower(),
		type = personType:lower(),
		game = Logic.emptyOr(args.game, playerInfo.extradata.game, args.defaultGame),
		id = args.id or playerInfo.id,
		idIPA = args.idIPA or playerInfo.extradata.idIPA,
		idAudio = args.idAudio or playerInfo.extradata.idAudio,
		birthDate = args.birthdate or playerInfo.birthdate,
		deathDate = args.deathdate or playerInfo.deathdate,
		nationality = args.nationality or playerInfo.nationality,
		nationality2 = args.nationality2 or playerInfo.nationality2,
		nationality3 = args.nationality3 or playerInfo.nationality3,
		faction = args.faction or playerInfo.extradata.faction,
		faction2 = args.faction2 or playerInfo.extradata.faction2,
		faction3 = args.faction3 or playerInfo.extradata.faction3,
		subText = args.subtext,
		freeText = args.freetext,
		role = role,
		role2 = (args.role2 or playerInfo.extradata.role2 or ''):lower(),
		firstName = Logic.emptyOr(args.firstname, playerInfo.extradata.firstname, table.remove(nameArray, 1)),
		lastName = Logic.emptyOr(args.lastname, playerInfo.extradata.lastname, nameArray[#nameArray]),
		formerlyKnownAs = readNames('formername'),
		alsoKnownAs = readNames('aka'),
	}
end


---@param queryType 'datapoint'?
---@return nil
function PlayerIntroduction:_readTransferData(queryType)
	self.transferInfo = {}

	if queryType == 'datapoint' then
		self:_readTransferFromDataPoints()
	else
		self:_readTransferFromTransfers()
	end

	if (self.transferInfo.type or 'current') == 'current' then
		-- use transfer role if same team as player page team input
		if String.isNotEmpty(self.playerInfo.team) and self.playerInfo.team ~= self.transferInfo.team then
			self.transferInfo.role = nil
		end
	end

	-- for retired players teams can only be former
	if self.playerInfo.status == 'retired' then
		self.transferInfo.type = TRANSFER_STATUS_FORMER
	end
end

function PlayerIntroduction:_readTransferFromDataPoints()
	local queryData = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[pagename::' .. self.player .. ']] AND [[type::teamhistory]] AND '
			.. '[[extradata_joindate::>]] AND [[extradata_leavedate::>]]',
		query = 'information, extradata',
	})

	if type(queryData) == 'table' then
		table.sort(queryData, function (dataPoint1, dataPoint2)
			local extradata1 = dataPoint1.extradata
			local extradata2 = dataPoint2.extradata
			return extradata1.leavedate > extradata2.leavedate
				or extradata1.leavedate == extradata2.leavedate and extradata1.teamcount > extradata2.teamcount
		end)

		local extradata = queryData[1].extradata

		if extradata.leavedate and extradata.leavedate ~= DEFAULT_DATAPOINT_LEAVE_DATE then
			self.transferInfo = {
				date = extradata.leavedate,
				team = queryData[1].information,
				role = (extradata.role or ''):lower(),
				type = TRANSFER_STATUS_FORMER,
			}
		elseif (extradata.role or ''):lower() == TRANSFER_STATUS_LOAN then
			self.transferInfo = {
				date = os.time(),
				team = queryData[1].information,
				-- assuming previous team is main team if it's missing a leavedate
				team2 = queryData[2] and queryData[2].extradata.leavedate == DEFAULT_DATAPOINT_LEAVE_DATE and queryData[2].information,
				role = (extradata.role or ''):lower(),
				type = TRANSFER_STATUS_LOAN,
			}
		else
			self.transferInfo = {
				date = os.time(),
				team = queryData[1].information,
				role = (extradata.role or ''):lower(),
				type = TRANSFER_STATUS_CURRENT,
			}
		end
	end
end

function PlayerIntroduction:_readTransferFromTransfers()
	local queryData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = '([[player::' .. self.player .. ']] OR [[player::' .. self.player:gsub('_', ' ') .. ']]) AND '
			.. '[[date::>1971-01-01]]',
		order = 'date desc',
		limit = 1,
		query = 'fromteam, toteam, role2, date, extradata'
	})

	if type(queryData[1]) == 'table' then
		queryData = queryData[1]
		local extradata = queryData.extradata
		if String.isEmpty(queryData.toteam) then
			self.transferInfo = {
				date = queryData.date,
				team = queryData.fromteam,
				type = TRANSFER_STATUS_FORMER,
			}
		elseif String.isNotEmpty(extradata.toteamsec) and
			((queryData.role2):lower() == TRANSFER_STATUS_LOAN or (extradata.role2sec):lower() == TRANSFER_STATUS_LOAN) then

			if queryData.fromteam == queryData.toteam and (extradata.role2sec):lower() == TRANSFER_STATUS_LOAN then
				self.transferInfo = {
					date = os.time(),
					team = extradata.toteamsec,
					team2 = queryData.toteam,
					role = (extradata.role2):lower(),
					type = TRANSFER_STATUS_LOAN,
				}
			elseif queryData.fromteam == extradata.toteamsec and (queryData.role2):lower() == TRANSFER_STATUS_LOAN then
				self.transferInfo = {
					date = os.time(),
					team = queryData.toteam,
					team2 = extradata.toteamsec,
					role = (queryData.role2):lower(),
					type = TRANSFER_STATUS_LOAN,
				}
			else
				self.transferInfo = {
					date = os.time(),
					team = queryData.toteam,
					role = (queryData.role2):lower(),
					type = TRANSFER_STATUS_CURRENT,
				}
			end
		else
			self.transferInfo = {
				date = os.time(),
				team = queryData.toteam,
				role = (queryData.role2):lower(),
				type = TRANSFER_STATUS_CURRENT,
			}
		end
	end
end

---@param args table
---@return nil
function PlayerIntroduction:_roleAdjusts(args)
	local roleAdjust = Logic.readBool(args.convert_role) and mw.loadData('Module:PlayerIntroduction/role') or {}

	local manualRoleInput = args.role
	local transferInfo = self.transferInfo

	-- if you have a better name ...
	local tempRole
	if manualRoleInput ~= SKIP_ROLE and String.isNotEmpty(transferInfo.role) and
		transferInfo.role ~= 'inactive' and transferInfo.role ~= 'loan' and transferInfo.role ~= 'substitute' then

		tempRole = transferInfo.role
	elseif manualRoleInput ~= SKIP_ROLE then
		tempRole = self.playerInfo.role
	end

	tempRole = roleAdjust[tempRole] or tempRole

	if transferInfo.role == 'substitute' then
		tempRole = 'substitute ' .. tempRole
	end

	-- if you have a better name ...
	self.transferInfo.tempRole = tempRole
end

function PlayerIntroduction:create()

end









return PlayerIntroduction
