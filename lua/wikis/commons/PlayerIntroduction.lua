---
-- @Liquipedia
-- page=Module:PlayerIntroduction
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local AnOrA = Lua.import('Module:A or an')
local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Roles = Lua.import('Module:Roles')

local SHOULD_QUERY_KEYWORD = 'query'
local DEFAULT_DATAPOINT_LEAVE_DATE = '2999-01-01'
local TRANSFER_STATUS_FORMER = 'former'
local TRANSFER_STATUS_LOAN = 'loan'
local TRANSFER_STATUS_CURRENT = 'current'
local TYPE_PLAYER = 'player'
local SKIP_ROLE = 'skip'
local INACTIVE_ROLE = 'inactive'

---@class playerIntroArgsValues
---@field [1] string?
---@field player string?
---@field playerInfo string?
---@field birthdate string?
---@field deathdate string?
---@field defaultGame string?
---@field faction string?
---@field faction2 string?
---@field faction3 string?
---@field firstname string?
---@field lastname string?
---@field freetext string?
---@field game string?
---@field id string?
---@field name string?
---@field nationality string?
---@field nationality2 string?
---@field nationality3 string?
---@field roles string[]|string|nil
---@field status string?
---@field subtext string?
---@field team string?
---@field team2 string?
---@field type string?
---@field transferquery string?
---@field convert_role boolean?
---@field show_role boolean?
---@field show_faction boolean?
---@field formername1 string?
---@field formername2 string?
---@field formername3 string?
---@field aka1 string?
---@field aka2 string?
---@field aka3 string?

---@class PlayerIntroduction
---@operator call(playerIntroArgsValues): PlayerIntroduction
---@field player string
---@field args playerIntroArgsValues
---@field playerInfo table
---@field transferInfo table
local PlayerIntroduction = Class.new(function(self, ...) self:init(...) end)

-- template entry point for PlayerIntroduction
---@param frame Frame
---@return string
function PlayerIntroduction.templatePlayerIntroduction(frame)
	return PlayerIntroduction.run(Arguments.getArgs(frame))
end

-- module entry point for PlayerIntroduction
---@param args playerIntroArgsValues?
---@return string
function PlayerIntroduction.run(args)
	return PlayerIntroduction(args):queryPlayerInfo():queryTransferData(true):adjustData():create()
end

-- template entry point for PlayerTeamAuto
---@param frame Frame
---@return string
function PlayerIntroduction.templatePlayerTeamAuto(frame)
	local args = Arguments.getArgs(frame)
	local team, team2 = PlayerIntroduction.playerTeamAuto(args)

	return args.team == 'team2' and (team2 or '') or team or ''
end

-- module entry point for PlayerTeamAuto
---@param args playerIntroArgsValues?
---@return string?
---@return string?
function PlayerIntroduction.playerTeamAuto(args)
	return PlayerIntroduction(args):queryTransferData(false):returnTeams()
end

--- Init function for PlayerIntroduction
---@param args playerIntroArgsValues?
---@return self
function PlayerIntroduction:init(args)
	args = args or {}
	self.args = args

	self.player = mw.ext.TeamLiquidIntegration.resolve_redirect(
		args.player or args[1] or mw.title.getCurrentTitle().text
	):gsub(' ', '_')

	return self
end

---@return self
function PlayerIntroduction:queryPlayerInfo()
	local playerInfo = {}
	if Logic.emptyOr(self.args.playerInfo, SHOULD_QUERY_KEYWORD) == SHOULD_QUERY_KEYWORD then
		playerInfo = self:_playerQuery()
	end

	self:_parsePlayerInfo(self.args, playerInfo)

	return self
end

---@param queryOnlyIfPlayerInfoIsPresent boolean
---@return self
function PlayerIntroduction:queryTransferData(queryOnlyIfPlayerInfoIsPresent)
	if queryOnlyIfPlayerInfoIsPresent and Table.isEmpty(self.playerInfo) then
		return self
	end

	-- can not use `:` here due to `Module:PlayerTeamAuto`
	self.transferInfo = PlayerIntroduction._readTransferData(self.player, self.args.transferquery == 'datapoint')

	return self
end

---@return string?
---@return string?
function PlayerIntroduction:returnTeams()
	local transfer = self.transferInfo
	if not transfer or (transfer.type ~= 'current' and transfer.type ~= 'loan') then
		return
	end

	return transfer.team, transfer.team2
end

---@return self
function PlayerIntroduction:adjustData()
	self:_adjustTransferData()

	self:_roleAdjusts(self.args)

	self.options = {
		showRole = Logic.readBool(self.args.show_role),
		showFaction = Logic.readBool(self.args.show_faction),
	}

	return self
end

---@return table
function PlayerIntroduction:_playerQuery()
	local queryData = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. self.player .. ']]',
		query = 'id, name, localizedname, type, nationality, nationality, nationality2, nationality3, '
			.. 'birthdate, deathdate, status, extradata, teampagename',
	})

	assert(type(queryData) == 'table', queryData)

	return queryData[1] or {}
end

---@param args playerIntroArgsValues
---@param playerInfo table
function PlayerIntroduction:_parsePlayerInfo(args, playerInfo)
	playerInfo.extradata = playerInfo.extradata or {}

	local roles = args.roles or playerInfo.extradata.roles or {}
	if type(roles) == 'string' then
		roles = Array.parseCommaSeparatedString(roles)
	end

	local personType = (Logic.emptyOr(args.type, playerInfo.type) or TYPE_PLAYER):lower()
	if personType ~= TYPE_PLAYER and Roles.All[roles[1]] then
		personType = Roles.All[roles[1]].display or TYPE_PLAYER
	end

	local name = args.name or playerInfo.name

	local nameArray = String.isNotEmpty(name)
		and mw.text.split(name, ' ')
		or {}

	local function readNames(prefix)
		return Array.extractValues(Table.filterByKey(args, function(key)
			return key:find('^' .. prefix .. '%d+$') ~= nil
		end) or {})
	end

	self.playerInfo = {
		team = Logic.emptyOr(args.team, playerInfo.teampagename),
		team2 = Logic.emptyOr(args.team2, playerInfo.extradata.team2),
		name = name,
		status = Logic.emptyOr(args.status, playerInfo.status, 'active'):lower(),
		type = personType:lower(),
		game = Logic.emptyOr(args.game, playerInfo.extradata.game, args.defaultGame),
		id = Logic.emptyOr(args.id, playerInfo.id),
		birthDate = Logic.emptyOr(args.birthdate, playerInfo.birthdate, DateExt.defaultDate),
		deathDate = Logic.emptyOr(args.deathdate, playerInfo.deathdate, DateExt.defaultDate),
		nationality = Logic.emptyOr(args.nationality, playerInfo.nationality),
		nationality2 = Logic.emptyOr(args.nationality2, playerInfo.nationality2),
		nationality3 = Logic.emptyOr(args.nationality3, playerInfo.nationality3),
		faction = Logic.emptyOr(args.faction, playerInfo.extradata.faction),
		faction2 = Logic.emptyOr(args.faction2, playerInfo.extradata.faction2),
		faction3 = Logic.emptyOr(args.faction3, playerInfo.extradata.faction3),
		subText = args.subtext,
		freeText = args.freetext,
		roles = roles,
		firstName = Logic.emptyOr(args.firstname, playerInfo.extradata.firstname, table.remove(nameArray, 1)),
		lastName = Logic.emptyOr(args.lastname, playerInfo.extradata.lastname, nameArray[#nameArray]),
		formerlyKnownAs = readNames('formername'),
		alsoKnownAs = readNames('aka'),
	}
end

---@param player string
---@param queryFromDataPoint boolean
---@return table
function PlayerIntroduction._readTransferData(player, queryFromDataPoint)
	if queryFromDataPoint then
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

	if type(queryData[1]) ~= 'table' then
		return {}
	end

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

---@param player string
---@return table?
function PlayerIntroduction._readTransferFromTransfers(player)
	local queryData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = '([[player::' .. player .. ']] OR [[player::' .. player:gsub('_', ' ') .. ']]) AND '
			.. '[[date::!' .. DateExt.defaultDate .. ']]',
		order = 'date desc',
		limit = 1,
		query = 'fromteam, toteam, role2, date, extradata'
	})

	if type(queryData[1]) ~= 'table' then
		return {}
	end

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

---@param args playerIntroArgsValues
function PlayerIntroduction:_roleAdjusts(args)
	local skipRole = Array.any(self.playerInfo.roles, function (role)
		return role == SKIP_ROLE
	end)
	local transferInfo = self.transferInfo

	local role
	if not skipRole and String.isNotEmpty(transferInfo.role) and
		transferInfo.role ~= INACTIVE_ROLE and transferInfo.role ~= 'loan' and transferInfo.role ~= 'substitute' then

		role = transferInfo.role
	elseif not skipRole then
		role = self.playerInfo.roles[1]
	end

	role = Roles.All[role] and Roles.All[role].display or role

	if transferInfo.role == 'substitute' then
		role = 'substitute ' .. role
	end

	self.transferInfo.standardizedRole = role
end

--- builds the display
---@return string
function PlayerIntroduction:create()
	if Logic.isEmpty(self.playerInfo.id) then
		return ''
	end

	local isDeceased = self.playerInfo.deathDate ~= DateExt.defaultDate or self.playerInfo.status == 'passed away'

	local statusDisplay = self:_statusDisplay(isDeceased)
	local nationalityDisplay = self:_nationalityDisplay()
	local gameDisplay = self:_gameDisplay()
	local factionDisplay = self:_factionDisplay()
	local typeDisplay = self:typeDisplay()

	return String.interpolate('${name}${born} ${tense} ${a}${status}${nationality}${game}'
		.. '${faction}${type}${team}${subText}.${freeText}', {
			name = self:nameDisplay(),
			born = self:_bornDisplay(isDeceased),
			tense = isDeceased and 'was' or 'is',
			a = AnOrA._main{
				statusDisplay or nationalityDisplay or gameDisplay or factionDisplay or typeDisplay,
				origStr = 'false' -- hate it, but has to be like this
			},
			status = statusDisplay or '',
			nationality = nationalityDisplay or '',
			game = gameDisplay or '',
			faction = factionDisplay or '',
			type = typeDisplay or '',
			team = self:_teamDisplay(isDeceased) or '',
			subText = self._addConcatText(self.playerInfo.subText),
			freeText = self._addConcatText(self.playerInfo.freeText),
		}
	)
end

--- builds the name display
---@return string
function PlayerIntroduction:nameDisplay()
	local nameQuotes = String.isNotEmpty(self.playerInfo.name) and '"' or ''

	local nameDisplay = self._addConcatText(self.playerInfo.firstName, nil, true)
		.. nameQuotes .. '<b>' .. self.playerInfo.id .. '</b>' .. nameQuotes
		.. self._addConcatText(self.playerInfo.lastName)

	if Table.isNotEmpty(self.playerInfo.formerlyKnownAs) then
		nameDisplay = nameDisplay .. self._addConcatText('(formerly known as ')
			.. mw.text.listToText(self.playerInfo.formerlyKnownAs, ', ', ' and ')
			.. ')'
	end

	if Table.isNotEmpty(self.playerInfo.alsoKnownAs) then
		nameDisplay = nameDisplay .. self._addConcatText('(also known as ')
			.. mw.text.listToText(self.playerInfo.alsoKnownAs, ', ', ' and ')
			.. ')'
	end

	return nameDisplay
end

--- builds the born display
---@param isDeceased boolean
---@return string
function PlayerIntroduction:_bornDisplay(isDeceased)
	if self.playerInfo.birthDate == DateExt.defaultDate then
		return ''
	end

	local displayDate = function(dateString)
		return os.date("!%B %e, %Y", tonumber(mw.getContentLanguage():formatDate('U', dateString)))
	end

	if not isDeceased then
		return ' (born ' .. displayDate(self.playerInfo.birthDate) .. ')'
	elseif self.playerInfo.deathDate ~= DateExt.defaultDate then
		return ' ('
			.. displayDate(self.playerInfo.birthDate)
			.. ' – '
			.. displayDate(self.playerInfo.deathDate)
			.. ')'
	end

	return ''
end

--- builds the status display
---@param isDeceased boolean
---@return string?
function PlayerIntroduction:_statusDisplay(isDeceased)
	if self.playerInfo.status ~= 'active' and not isDeceased then
		return self._addConcatText(self.playerInfo.status)
	end

	return nil
end

--- builds the nationality display
---@return string?
function PlayerIntroduction:_nationalityDisplay()
	local nationalities = {}
	for _, nationality in Table.iter.pairsByPrefix(self.playerInfo, 'nationality', {requireIndex = false}) do
		table.insert(nationalities, '[[:Category:' .. nationality
				.. '|' .. (Flags.getLocalisation(nationality) or '') .. ']]')
	end

	if Table.isEmpty(nationalities) then
		return nil
	end

	return self._addConcatText(table.concat(nationalities, '/'))
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
function PlayerIntroduction:typeDisplay()
	if self.playerInfo.type == TYPE_PLAYER then
		return self._addConcatText(self.playerInfo.type)
	end
	local function roleDisplay(role)
		return Roles.All[role] and Roles.All[role].display or role
	end
	return self._addConcatText(mw.text.listToText(Array.map(self.playerInfo.roles, roleDisplay), ', ', ' and '))
end

--- builds the team and role display
---@param isDeceased boolean
---@return string?
function PlayerIntroduction:_teamDisplay(isDeceased)
	local playerInfo = self.playerInfo
	local transferInfo = self.transferInfo
	local role = self.transferInfo.standardizedRole
	if String.isEmpty(playerInfo.team) and (String.isEmpty(transferInfo.team) or transferInfo.team == SKIP_ROLE) then
		return nil
	end

	local isCurrentTense = String.isNotEmpty(playerInfo.team) and not isDeceased

	local shouldDisplayTeam2 = isCurrentTense
		and transferInfo.type == TRANSFER_STATUS_LOAN
		and String.isNotEmpty(playerInfo.team2)

	local hasAppendedRoleDisplay = self.options.showRole and playerInfo.type ~= TYPE_PLAYER and String.isNotEmpty(role)

	return String.interpolate(' ${tense} ${playedOrWorked} ${team}${team2}${roleDisplay}', {
		tense = isCurrentTense and 'who is currently' or 'who last',
		playedOrWorked = self:playedOrWorked(isCurrentTense),
		team = PlayerIntroduction._displayTeam(isCurrentTense and playerInfo.team or transferInfo.team, transferInfo.date),
		team2 = shouldDisplayTeam2
			and (' on loan from' .. PlayerIntroduction._displayTeam(playerInfo.team2, transferInfo.date))
			or '',
		roleDisplay = hasAppendedRoleDisplay and (' as ' .. AnOrA.main{role}) or ''
	})

end

---@param isCurrentTense boolean
---@return string
function PlayerIntroduction:playedOrWorked(isCurrentTense)
	local playerInfo = self.playerInfo
	local transferInfo = self.transferInfo
	local role = self.transferInfo.standardizedRole

	if playerInfo.type ~= TYPE_PLAYER and isCurrentTense then
		return 'working for'
	elseif playerInfo.type ~= TYPE_PLAYER then
		return 'worked for'
	elseif not isCurrentTense then
		return 'played for'
	elseif transferInfo.role == INACTIVE_ROLE and transferInfo.type == TRANSFER_STATUS_CURRENT then
		return 'on the inactive roster of'
	elseif self.options.showRole and role == 'streamer' or role == 'content creator' then
		return AnOrA.main{role} .. ' for'
	elseif self.options.showRole and String.isNotEmpty(role) then
		return 'playing as ' .. AnOrA.main{role} .. ' for'
	end

	return ' playing for'
end

---@param team string
---@param date string
---@return string
function PlayerIntroduction._displayTeam(team, date)
	team = team:gsub('_', ' ')

	local rawTeam = mw.ext.TeamTemplate.raw(team, date)
	if rawTeam then
		return ' [[' .. rawTeam.page .. '|' .. rawTeam.name .. ']]'
	end

	return ' [[' .. team .. ']]'
end

---@param text string|nil
---@param delimiter string?
---@param suffix boolean?
---@return string
function PlayerIntroduction._addConcatText(text, delimiter, suffix)
	if not text then
		return ''
	end

	delimiter = delimiter or ' '

	return suffix and (text .. delimiter)
		or (delimiter .. text)
end

return PlayerIntroduction
