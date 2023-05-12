---
-- @Liquipedia
-- wiki=commons
-- page=Module:PlayerIntroduction
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local AnOrA = require('Module:A or an')
local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local SHOULD_QUERY_KEYWORD = 'query'
local DEFAULT_DATAPOINT_LEAVE_DATE = '2999-01-01'
local TRANSFER_STATUS_FORMER = 'former'
local TRANSFER_STATUS_LOAN = 'loan'
local TRANSFER_STATUS_CURRENT = 'current'
local TYPE_PLAYER = 'player'
local SKIP_ROLE = 'skip'
local INACTIVE_ROLE = 'inactive'
local DEFAULT_DATE = '1970-01-01'

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

---@deprecated
--- only legacy support for `Module:PlayerTeamAuto`
function PlayerIntroduction._get_lpdbtransfer(player, queryType)
	return PlayerIntroduction._readTransferData(player, queryType)
end

-- template entry point
function PlayerIntroduction.templatePlayerIntroduction(frame)
	return PlayerIntroduction.run(Arguments.getArgs(frame))
end

-- module entry point
function PlayerIntroduction.run(args)
	return PlayerIntroduction(args):create()
end

---@class argsValues
---@field [1] string?,
---@field player string?,
---@field playerInfo string?,
---@field birthdate string?,
---@field deathdate string?,
---@field defaultGame string?,
---@field faction string?,
---@field faction2 string?,
---@field faction3 string?,
---@field firstname string?,
---@field lastname string?,
---@field freetext string?,
---@field game string?,
---@field id string?,
---@field idAudio string?,
---@field idIPA string?,
---@field name string?,
---@field nationality string?,
---@field nationality2 string?,
---@field nationality3 string?,
---@field role string?,
---@field role2 string?,
---@field status string?,
---@field subtext string?,
---@field team string?,
---@field team2 string?,
---@field type string?,
---@field transferquery 'datapoint'?,
---@field convert_role boolean?,
---@field show_role boolean?,
---@field show_faction boolean?
---@field formernameX string?,
---@field akaX string?,

--- Init function for PlayerIntroduction
---@param args argsValues
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

	if Table.isEmpty(self.playerInfo) then
		return self
	end

	-- can not use `:` here due to `Module:PlayerTeamAuto`
	self.transferInfo = PlayerIntroduction._readTransferData(self.player, args.transferquery)

	self:_adjustTransferData()

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

---@param args argsValues
---@param playerInfo table
---@return nil
function PlayerIntroduction:_parsePlayerInfo(args, playerInfo)
	playerInfo.extradata = playerInfo.extradata or {}

	local role = (args.role or playerInfo.extradata.role or ''):lower()

	local personType = Logic.emptyOr(args.type, playerInfo.type, TYPE_PLAYER):lower()
	if personType ~= TYPE_PLAYER and String.isNotEmpty(role) then
		personType = role
	end

	local name = args.name or playerInfo.name

	local nameArray = String.isNotEmpty(name)
		and mw.text.split(name, ' ')
		or {}

	local function readNames(prefix)
		return Array.extractValues(Table.filterByKey(args, function(key) return key:find('^' .. prefix .. '%d+$') end) or {})
	end

	self.playerInfo = {
		team = Logic.emptyOr(args.team, playerInfo.teampagename),
		team2 = Logic.emptyOr(args.team2, playerInfo.extradata.team2),
		name = name,
		status = Logic.emptyOr(args.status, playerInfo.status, 'active'):lower(),
		type = personType:lower(),
		game = Logic.emptyOr(args.game, playerInfo.extradata.game, args.defaultGame),
		id = Logic.emptyOr(args.id, playerInfo.id),
		idIPA = Logic.emptyOr(args.idIPA, playerInfo.extradata.idIPA),
		idAudio = Logic.emptyOr(args.idAudio, playerInfo.extradata.idAudio),
		birthDate = Logic.emptyOr(args.birthdate, playerInfo.birthdate),
		deathDate = Logic.emptyOr(args.deathdate, playerInfo.deathdate),
		nationality = Logic.emptyOr(args.nationality, playerInfo.nationality),
		nationality2 = Logic.emptyOr(args.nationality2, playerInfo.nationality2),
		nationality3 = Logic.emptyOr(args.nationality3, playerInfo.nationality3),
		faction = Logic.emptyOr(args.faction, playerInfo.extradata.faction),
		faction2 = Logic.emptyOr(args.faction2, playerInfo.extradata.faction2),
		faction3 = Logic.emptyOr(args.faction3, playerInfo.extradata.faction3),
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

---@param player string
---@param queryType 'datapoint'?
---@return table
function PlayerIntroduction._readTransferData(player, queryType)
	if queryType == 'datapoint' then
		return PlayerIntroduction._readTransferFromDataPoints(player) or {}
	end

	return PlayerIntroduction._readTransferFromTransfers(player) or {}
end

function PlayerIntroduction:_adjustTransferData()
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

---@param player string
---@return table?
function PlayerIntroduction._readTransferFromDataPoints(player)
	local queryData = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[pagename::' .. player .. ']] AND [[type::teamhistory]] AND '
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
			return {
				date = extradata.leavedate,
				team = queryData[1].information,
				role = (extradata.role or ''):lower(),
				type = TRANSFER_STATUS_FORMER,
			}
		elseif (extradata.role or ''):lower() == TRANSFER_STATUS_LOAN then
			return {
				date = os.time(),
				team = queryData[1].information,
				-- assuming previous team is main team if it's missing a leavedate
				team2 = queryData[2] and queryData[2].extradata.leavedate == DEFAULT_DATAPOINT_LEAVE_DATE
					and queryData[2].information or nil,
				role = (extradata.role or ''):lower(),
				type = TRANSFER_STATUS_LOAN,
			}
		else
			return {
				date = os.time(),
				team = queryData[1].information,
				role = (extradata.role or ''):lower(),
				type = TRANSFER_STATUS_CURRENT,
			}
		end
	end
end

---@param player string
---@return table?
function PlayerIntroduction._readTransferFromTransfers(player)
	local queryData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = '([[player::' .. player .. ']] OR [[player::' .. player:gsub('_', ' ') .. ']]) AND '
			.. '[[date::>1971-01-01]]',
		order = 'date desc',
		limit = 1,
		query = 'fromteam, toteam, role2, date, extradata'
	})

	if type(queryData[1]) == 'table' then
		queryData = queryData[1]
		local extradata = queryData.extradata
		if String.isEmpty(queryData.toteam) then
			return {
				date = queryData.date,
				team = queryData.fromteam,
				type = TRANSFER_STATUS_FORMER,
			}
		elseif String.isNotEmpty(extradata.toteamsec) and
			((queryData.role2):lower() == TRANSFER_STATUS_LOAN or (extradata.role2sec):lower() == TRANSFER_STATUS_LOAN) then

			if queryData.fromteam == queryData.toteam and (extradata.role2sec):lower() == TRANSFER_STATUS_LOAN then
				return {
					date = os.time(),
					team = extradata.toteamsec,
					team2 = queryData.toteam,
					role = (extradata.role2):lower(),
					type = TRANSFER_STATUS_LOAN,
				}
			elseif queryData.fromteam == extradata.toteamsec and (queryData.role2):lower() == TRANSFER_STATUS_LOAN then
				return {
					date = os.time(),
					team = queryData.toteam,
					team2 = extradata.toteamsec,
					role = (queryData.role2):lower(),
					type = TRANSFER_STATUS_LOAN,
				}
			else
				return {
					date = os.time(),
					team = queryData.toteam,
					role = (queryData.role2):lower(),
					type = TRANSFER_STATUS_CURRENT,
				}
			end
		else
			return {
				date = os.time(),
				team = queryData.toteam,
				role = (queryData.role2):lower(),
				type = TRANSFER_STATUS_CURRENT,
			}
		end
	end
end

---@param args argsValues
---@return nil
function PlayerIntroduction:_roleAdjusts(args)
	local roleAdjust = Logic.readBool(args.convert_role) and mw.loadData('Module:PlayerIntroduction/role') or {}

	local manualRoleInput = args.role
	local transferInfo = self.transferInfo

	-- if you have a better name ...
	local tempRole
	if manualRoleInput ~= SKIP_ROLE and String.isNotEmpty(transferInfo.role) and
		transferInfo.role ~= INACTIVE_ROLE and transferInfo.role ~= 'loan' and transferInfo.role ~= 'substitute' then

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

--- builds the display
---@return string
function PlayerIntroduction:create()
	if Table.isEmpty(self.playerInfo) then
		return ''
	end

	local isDeceased = self.playerInfo.deathDate ~= '1970-01-01' or self.playerInfo.status == 'passed away'

	local statusDisplay = self:_statusDisplay(isDeceased)
	local nationalityDisplay = self:_nationalityDisplay()
	local gameDisplay = self:_gameDisplay()
	local factionDisplay = self:_factionDisplay()
	local typeDisplay = self:_typeDisplay()

	return String.interpolate('${name}${born} ${tense} ${a}${status}${nationality}${game}'
		.. '${faction}${type}${team}${subText}.${freeText}', {
			name = self:_nameDisplay(),
			born = self:_bornDisplay(isDeceased),
			tense = isDeceased and 'was' or 'is',
			a = AnOrA._main{
				statusDisplay or nationalityDisplay or gameDisplay or factionDisplay or typeDisplay ,
				origStr = 'false' -- hate it, but has to be like this
			},
			status = statusDisplay or '',
			nationality = nationalityDisplay or '',
			game = gameDisplay or '',
			faction = factionDisplay or '',
			type = typeDisplay or '',
			team = self:_teamDisplay(isDeceased),
			subText = self.playerInfo.subText or '',
			freeText = self.playerInfo.freeText or '',
		}
	)
end

--- builds the name display
---@return string
function PlayerIntroduction:_nameDisplay()
	local nameQuotes = String.isNotEmpty(self.playerInfo.name) and '"' or ''

	local nameDisplay = self._addConcatText(self.playerInfo.firstName, nil, true)
		.. nameQuotes .. '<b>' .. self.playerInfo.id .. '</b>' .. nameQuotes

	if String.isNotEmpty(self.playerInfo.idAudio) or String.isNotEmpty(self.playerInfo.idIPA) then
		nameDisplay = nameDisplay .. '(' .. self._addConcatText(self.playerInfo.idIPA, ', ')
			.. (String.isNotEmpty(self.playerInfo.idAudio)
				-- TODO: convert the template to a module
				and Template.safeExpand(mw.getCurrentFrame(), 'Audio', {self.playerInfo.idAudio, 'listen', help = 'no'})
				or '')
			.. ')'
	end

	nameDisplay = nameDisplay .. self._addConcatText(self.playerInfo.lastName)

	if Table.isNotEmpty(self.playerInfo.formerlyKnownAs) then
		nameDisplay = nameDisplay .. self._addConcatText('(formerly known as')
			.. mw.text.listToText(self.playerInfo.formerlyKnownAs, ', ', ' and ')
			.. ')'
	end

	if Table.isNotEmpty(self.playerInfo.alsoKnownAs) then
		nameDisplay = nameDisplay .. self._addConcatText('(also known as')
			.. mw.text.listToText(self.playerInfo.alsoKnownAs, ', ', ' and ')
			.. ')'
	end

	return nameDisplay
end

--- builds the born display
---@param isDeceased boolean
---@return string
function PlayerIntroduction:_bornDisplay(isDeceased)
	if self.playerInfo.birthDate == DEFAULT_DATE then
		return ''
	end

	if not isDeceased then
		return ' (born '
---@diagnostic disable-next-line: param-type-mismatch
			.. os.date("!%B %d, %Y", tonumber(mw.getContentLanguage():formatDate('U', self.playerInfo.birthDate))):gsub(' 0',' ')
			.. ')'
	elseif self.playerInfo.deathDate ~= DEFAULT_DATE then
		return ' ('
---@diagnostic disable-next-line: param-type-mismatch
			.. os.date("!%B %d, %Y", tonumber(mw.getContentLanguage():formatDate('U', self.playerInfo.birthDate))):gsub(' 0',' ')
			.. ' – '
---@diagnostic disable-next-line: param-type-mismatch
			.. os.date("!%B %d, %Y", tonumber(mw.getContentLanguage():formatDate('U', self.playerInfo.birthDate))):gsub(' 0',' ')
			.. ')'
	end

	return ''
end

--- builds the status display
---@param isDeceased boolean
---@return string?
function PlayerIntroduction:_statusDisplay(isDeceased)
	if self.playerInfo.status ~= 'active' and not isDeceased then
		return self.playerInfo.status
	end

	return nil
end

--- builds the nationality display
---@return string?
function PlayerIntroduction:_nationalityDisplay()
	local nationalities = {}
	for _, nationality in Table.iter.pairsByPrefix(self.playerInfo, 'nationality', {requireIndex = false}) do
		table.insert(nationalities, '[[:Category:' .. nationality:gsub("^%l", string.upper)
				.. '|' .. (Flags.getLocalisation(nationality) or '') .. ']]')
	end

	if Table.isEmpty(nationalities) then
		return nil
	end

	return table.concat(nationalities, '/')
end

--- builds the game display
---@return string?
function PlayerIntroduction:_gameDisplay()
	if String.isEmpty(self.playerInfo.game) then
		return nil
	end

	return self._addConcatText('<i>' .. self.playerInfo.game .. '</i>')
end

--- builds the faction display
---@return string?
function PlayerIntroduction:_factionDisplay()
	if not self.options.showFaction or String.isEmpty(self.playerInfo.faction) or self.playerInfo.type ~= TYPE_PLAYER then
		return nil
	end

	local factions = {}
	for _, faction in Table.iter.pairsByPrefix(self.playerInfo, 'faction', {requireIndex = false}) do
		table.insert(factions, '[[:Category:' .. faction .. '|' .. faction .. ']]')
	end

	return self._addConcatText(mw.text.listToText(factions, ', ', ' and '))
end

--- builds the type display
---@return string?
function PlayerIntroduction:_typeDisplay()
	return self._addConcatText(self.playerInfo.type)
		.. self._addConcatText(
			self.playerInfo.type ~= TYPE_PLAYER and String.isNotEmpty(self.playerInfo.role2) and self.playerInfo.role2,
		' and ')
end

--- builds the team and role display
---@param isDeceased boolean
---@return string?
function PlayerIntroduction:_teamDisplay(isDeceased)
	local playerInfo = self.playerInfo
	local transferInfo = self.transferInfo
	local tempRole = self.transferInfo.tempRole
	if String.isEmpty(playerInfo.team) and (String.isEmpty(transferInfo.team) or transferInfo.team == SKIP_ROLE) then
		return nil
	end

	local teamDisplay
	if String.isNotEmpty(playerInfo.team) and not isDeceased then
		teamDisplay = ' who is currently'

		if playerInfo.type == TYPE_PLAYER then
			if transferInfo.role == INACTIVE_ROLE and transferInfo.type == TRANSFER_STATUS_CURRENT then
				teamDisplay = teamDisplay .. ' on the inactive roster of'
			elseif self.options.showRole and tempRole then
				if tempRole == 'streamer' or tempRole == 'content creator' then
					teamDisplay = teamDisplay .. ' ' .. AnOrA.main{tempRole}
				else
					teamDisplay = teamDisplay .. ' playing as ' .. AnOrA.main{tempRole}
				end
				teamDisplay = teamDisplay .. ' for'
			else
				teamDisplay = teamDisplay .. ' playing for'
			end
		else
			teamDisplay = teamDisplay .. ' working for'
		end

		teamDisplay = teamDisplay .. PlayerIntroduction._displayTeam(playerInfo.team, transferInfo.date)

		if transferInfo.type == TRANSFER_STATUS_LOAN and String.isEmpty(playerInfo.team2) then
			teamDisplay = teamDisplay .. ' on loan from' .. PlayerIntroduction._displayTeam(playerInfo.team2, transferInfo.date)
		end
	elseif String.isNotEmpty(transferInfo.team) and transferInfo.team ~= SKIP_ROLE
		and transferInfo.type == TRANSFER_STATUS_FORMER then

			teamDisplay = ' who last'
			if playerInfo.type == TYPE_PLAYER then
				teamDisplay = teamDisplay .. ' played'
			else
				teamDisplay = teamDisplay .. ' worked'
			end

			teamDisplay = teamDisplay .. ' for' .. PlayerIntroduction._displayTeam(transferInfo.team, transferInfo.date)
	end


	if self.options.showRole and playerInfo.type ~= TYPE_PLAYER and String.isNotEmpty(tempRole) then
		teamDisplay = teamDisplay .. ' as ' .. AnOrA.main{tempRole}
	end

	return teamDisplay
end

function PlayerIntroduction._displayTeam(team, date)
	if mw.ext.TeamTemplate.teamexists(team) then
		local rawTeam = mw.ext.TeamTemplate.raw(team, date)
		return ' [[' .. rawTeam.page .. '|' .. rawTeam.name .. ']]'
	end

	return ' [[' .. team .. ']]'
end

---@param text string|false|nil
---@param concatDelimiter string?
---@return string
function PlayerIntroduction._addConcatText(text, concatDelimiter, concatAfter)
	if not text then
		return ''
	end

	concatDelimiter = concatDelimiter or ' '

	return concatAfter and (text .. concatDelimiter)
		or (concatDelimiter .. text)
end

return PlayerIntroduction
