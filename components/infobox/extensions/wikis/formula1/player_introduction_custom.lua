---
-- @Liquipedia
-- wiki=formula1
-- page=Module:PlayerIntroduction/Custom
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

local SHOULD_QUERY_KEYWORD = 'query'
local DEFAULT_DATAPOINT_LEAVE_DATE = '2999-01-01'
local TRANSFER_STATUS_FORMER = 'former'
local TRANSFER_STATUS_LOAN = 'loan'
local TRANSFER_STATUS_CURRENT = 'current'
local TYPE_DRIVER = 'driver'
local SKIP_ROLE = 'skip'
local INACTIVE_ROLE = 'inactive'
local DEFAULT_DATE = '1970-01-01'

---@class playerIntroArgsValues
---@field [1] string?
---@field driver string?
---@field driverInfo string?
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
---@field role string?
---@field role2 string?
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

---@class DriverIntroduction
---@operator call(playerIntroArgsValues): DriverIntroduction
---@field driver string
---@field args playerIntroArgsValues
---@field driverInfo table
---@field transferInfo table
local DriverIntroduction = Class.new(function(self, ...) self:init(...) end)

-- template entry point for DriverIntroduction
---@param frame Frame
---@return string
function DriverIntroduction.templateDriverIntroduction(frame)
	return DriverIntroduction.run(Arguments.getArgs(frame))
end

-- module entry point for DriverIntroduction
---@param args playerIntroArgsValues?
---@return string
function DriverIntroduction.run(args)
	return DriverIntroduction(args):queryDriverInfo():queryTransferData(true):adjustData():create()
end

-- template entry point for DriverTeamAuto
---@param frame Frame
---@return string
function DriverIntroduction.templateDriverTeamAuto(frame)
	local args = Arguments.getArgs(frame)
	local team, team2 = DriverIntroduction.DriverTeamAuto(args)

	return args.team == 'team2' and (team2 or '') or team or ''
end

-- module entry point for DriverTeamAuto
---@param args playerIntroArgsValues?
---@return string?
---@return string?
function DriverIntroduction.driverTeamAuto(args)
	return DriverIntroduction(args):queryTransferData(false):returnTeams()
end

--- Init function for DriverIntroduction
---@param args playerIntroArgsValues?
---@return self
function DriverIntroduction:init(args)
	args = args or {}
	self.args = args

	self.driver = mw.ext.TeamLiquidIntegration.resolve_redirect(
		args.driver or args[1] or mw.title.getCurrentTitle().text
	):gsub(' ', '_')

	return self
end

---@return self
function DriverIntroduction:queryDriverInfo()
	local driverInfo = {}
	if Logic.emptyOr(self.args.driverInfo, SHOULD_QUERY_KEYWORD) == SHOULD_QUERY_KEYWORD then
		driverInfo = self:_driverQuery()
	end

	self:_parseDriverInfo(self.args, driverInfo)

	return self
end

---@param queryOnlyIfDriverInfoIsPresent boolean
---@return self
function DriverIntroduction:queryTransferData(queryOnlyIfDriverInfoIsPresent)
	if queryOnlyIfDriverInfoIsPresent and Table.isEmpty(self.driverInfo) then
		return self
	end

	-- can not use `:` here due to `Module:DriverTeamAuto`
	self.transferInfo = DriverIntroduction._readTransferData(self.driver, self.args.transferquery == 'datapoint')

	return self
end

---@return string?
---@return string?
function DriverIntroduction:returnTeams()
	local transfer = self.transferInfo
	if not transfer or (transfer.type ~= 'current' and transfer.type ~= 'loan') then
		return
	end

	return transfer.team, transfer.team2
end

---@return self
function DriverIntroduction:adjustData()
	self:_adjustTransferData()

	self:_roleAdjusts(self.args)

	self.options = {
		showRole = Logic.readBool(self.args.show_role),
		showFaction = Logic.readBool(self.args.show_faction),
	}

	return self
end

---@return table
function DriverIntroduction:_driverQuery()
	local queryData = mw.ext.LiquipediaDB.lpdb('driver', {
		conditions = '[[pagename::' .. self.driver .. ']]',
		query = 'id, name, localizedname, type, nationality, nationality, nationality2, nationality3, '
			.. 'birthdate, deathdate, status, extradata, teampagename',
	})

	assert(type(queryData) == 'table', queryData)

	return queryData[1] or {}
end

---@param args playerIntroArgsValues
---@param driverInfo table
function DriverIntroduction:_parseDriverInfo(args, driverInfo)
	driverInfo.extradata = driverInfo.extradata or {}

	local role = (args.role or driverInfo.extradata.role or ''):lower()

	local personType = Logic.emptyOr(args.type, driverInfo.type, TYPE_DRIVER):lower()
	if personType ~= TYPE_DRIVER and String.isNotEmpty(role) then
		personType = role
	end

	local name = args.name or driverInfo.name

	local nameArray = String.isNotEmpty(name)
		and mw.text.split(name, ' ')
		or {}

	local function readNames(prefix)
		return Array.extractValues(Table.filterByKey(args, function(key)
			return key:find('^' .. prefix .. '%d+$') ~= nil
		end) or {})
	end

	self.driverInfo = {
		team = Logic.emptyOr(args.team, driverInfo.teampagename),
		team2 = Logic.emptyOr(args.team2, driverInfo.extradata.team2),
		name = name,
		status = Logic.emptyOr(args.status, driverInfo.status, 'active'):lower(),
		type = personType:lower(),
		game = Logic.emptyOr(args.game, driverInfo.extradata.game, args.defaultGame),
		id = Logic.emptyOr(args.id, driverInfo.id),
		birthDate = Logic.emptyOr(args.birthdate, driverInfo.birthdate, DEFAULT_DATE),
		deathDate = Logic.emptyOr(args.deathdate, driverInfo.deathdate, DEFAULT_DATE),
		nationality = Logic.emptyOr(args.nationality, driverInfo.nationality),
		nationality2 = Logic.emptyOr(args.nationality2, driverInfo.nationality2),
		nationality3 = Logic.emptyOr(args.nationality3, driverInfo.nationality3),
		faction = Logic.emptyOr(args.faction, driverInfo.extradata.faction),
		faction2 = Logic.emptyOr(args.faction2, driverInfo.extradata.faction2),
		faction3 = Logic.emptyOr(args.faction3, driverInfo.extradata.faction3),
		subText = args.subtext,
		freeText = args.freetext,
		role = role,
		role2 = (args.role2 or driverInfo.extradata.role2 or ''):lower(),
		firstName = Logic.emptyOr(args.firstname, driverInfo.extradata.firstname, table.remove(nameArray, 1)),
		lastName = Logic.emptyOr(args.lastname, driverInfo.extradata.lastname, nameArray[#nameArray]),
		formerlyKnownAs = readNames('formername'),
		alsoKnownAs = readNames('aka'),
	}
end

---@param driver string
---@param queryFromDataPoint boolean
---@return table
function DriverIntroduction._readTransferData(driver, queryFromDataPoint)
	if queryFromDataPoint then
		return DriverIntroduction._readTransferFromDataPoints(driver) or {}
	end

	return DriverIntroduction._readTransferFromTransfers(driver) or {}
end

function DriverIntroduction:_adjustTransferData()
	if (self.transferInfo.type or 'current') == 'current' then
		-- use transfer role if same team as driver page team input
		if String.isNotEmpty(self.driverInfo.team) and self.driverInfo.team ~= self.transferInfo.team then
			self.transferInfo.role = nil
		end
	end

	-- for retired drivers teams can only be former
	if self.driverInfo.status == 'retired' then
		self.transferInfo.type = TRANSFER_STATUS_FORMER
	end
end

---@param driver string
---@return table?
function DriverIntroduction._readTransferFromDataPoints(driver)
	local queryData = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[pagename::' .. driver .. ']] AND [[type::teamhistory]] AND '
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

---@param driver string
---@return table?
function DriverIntroduction._readTransferFromTransfers(driver)
	local queryData = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = '([[driver::' .. driver .. ']] OR [[driver::' .. driver:gsub('_', ' ') .. ']]) AND '
			.. '[[date::>1971-01-01]]',
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
function DriverIntroduction:_roleAdjusts(args)
	local roleAdjust = Logic.readBool(args.convert_role) and mw.loadData('Module:DriverIntroduction/role') or {}

	local manualRoleInput = args.role
	local transferInfo = self.transferInfo

	local role
	if manualRoleInput ~= SKIP_ROLE and String.isNotEmpty(transferInfo.role) and
		transferInfo.role ~= INACTIVE_ROLE and transferInfo.role ~= 'loan' and transferInfo.role ~= 'substitute' then

		role = transferInfo.role
	elseif manualRoleInput ~= SKIP_ROLE then
		role = self.driverInfo.role
	end

	role = roleAdjust[role] or role

	if transferInfo.role == 'substitute' then
		role = 'substitute ' .. role
	end

	self.transferInfo.standardizedRole = role
end

--- builds the display
---@return string
function DriverIntroduction:create()
	if Logic.isEmpty(self.driverInfo.id) then
		return ''
	end

	local isDeceased = self.driverInfo.deathDate ~= '1970-01-01' or self.driverInfo.status == 'passed away'

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
			team = self:_teamDisplay(isDeceased) or '',
			subText = self._addConcatText(self.driverInfo.subText),
			freeText = self._addConcatText(self.driverInfo.freeText),
		}
	)
end

--- builds the name display
---@return string
function DriverIntroduction:_nameDisplay()
	local nameQuotes = String.isNotEmpty(self.driverInfo.name) and '"' or ''

	local nameDisplay = self._addConcatText(self.driverInfo.firstName, nil, true)
		.. nameQuotes .. '<b>' .. self.driverInfo.id .. '</b>' .. nameQuotes
		.. self._addConcatText(self.driverInfo.lastName)

	if Table.isNotEmpty(self.driverInfo.formerlyKnownAs) then
		nameDisplay = nameDisplay .. self._addConcatText('(formerly known as ')
			.. mw.text.listToText(self.driverInfo.formerlyKnownAs, ', ', ' and ')
			.. ')'
	end

	if Table.isNotEmpty(self.driverInfo.alsoKnownAs) then
		nameDisplay = nameDisplay .. self._addConcatText('(also known as ')
			.. mw.text.listToText(self.driverInfo.alsoKnownAs, ', ', ' and ')
			.. ')'
	end

	return nameDisplay
end

--- builds the born display
---@param isDeceased boolean
---@return string
function DriverIntroduction:_bornDisplay(isDeceased)
	if self.driverInfo.birthDate == DEFAULT_DATE then
		return ''
	end

	local displayDate = function(dateString)
		return os.date("!%B %e, %Y", tonumber(mw.getContentLanguage():formatDate('U', dateString)))
	end

	if not isDeceased then
		return ' (born ' .. displayDate(self.driverInfo.birthDate) .. ')'
	elseif self.driverInfo.deathDate ~= DEFAULT_DATE then
		return ' ('
			.. displayDate(self.driverInfo.birthDate)
			.. ' – '
			.. displayDate(self.driverInfo.deathDate)
			.. ')'
	end

	return ''
end

--- builds the status display
---@param isDeceased boolean
---@return string?
function DriverIntroduction:_statusDisplay(isDeceased)
	if self.driverInfo.status ~= 'active' and not isDeceased then
		return self._addConcatText(self.driverInfo.status)
	end

	return nil
end

--- builds the nationality display
---@return string?
function DriverIntroduction:_nationalityDisplay()
	local nationalities = {}
	for _, nationality in Table.iter.pairsByPrefix(self.driverInfo, 'nationality', {requireIndex = false}) do
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
function DriverIntroduction:_gameDisplay()
	if String.isEmpty(self.driverInfo.game) then
		return nil
	end

	return self._addConcatText('<i>' .. self.driverInfo.game .. '</i>')
end

--- builds the faction display
---@return string?
function DriverIntroduction:_factionDisplay()
	if not self.options.showFaction or String.isEmpty(self.driverInfo.faction) or self.driverInfo.type ~= TYPE_DRIVER then
		return nil
	end

	local factions = {}
	for _, faction in Table.iter.pairsByPrefix(self.driverInfo, 'faction', {requireIndex = false}) do
		table.insert(factions, '[[:Category:' .. faction .. '|' .. faction .. ']]')
	end

	return self._addConcatText(mw.text.listToText(factions, ', ', ' and '))
end

--- builds the type display
---@return string?
function DriverIntroduction:_typeDisplay()
	return self._addConcatText(self.driverInfo.type)
		.. self._addConcatText(
			self.driverInfo.type ~= TYPE_DRIVER and String.isNotEmpty(self.driverInfo.role2) and self.driverInfo.role2 or nil,
		' and ')
end

--- builds the team and role display
---@param isDeceased boolean
---@return string?
function DriverIntroduction:_teamDisplay(isDeceased)
	local driverInfo = self.driverInfo
	local transferInfo = self.transferInfo
	local role = self.transferInfo.standardizedRole
	if String.isEmpty(driverInfo.team) and (String.isEmpty(transferInfo.team) or transferInfo.team == SKIP_ROLE) then
		return nil
	end

	local isCurrentTense = String.isNotEmpty(driverInfo.team) and not isDeceased

	local shouldDisplayTeam2 = isCurrentTense
		and transferInfo.type == TRANSFER_STATUS_LOAN
		and String.isNotEmpty(driverInfo.team2)

	local hasAppendedRoleDisplay = self.options.showRole and driverInfo.type ~= TYPE_DRIVER and String.isNotEmpty(role)

	return String.interpolate(' ${tense} ${droveOrWorked} ${team}${team2}${roleDisplay}', {
		tense = isCurrentTense and 'who is currently' or 'who last',
		droveOrWorked = self:_droveOrWorked(isCurrentTense),
		team = DriverIntroduction._displayTeam(isCurrentTense and driverInfo.team or transferInfo.team, transferInfo.date),
		team2 = shouldDisplayTeam2
			and (' on loan from' .. DriverIntroduction._displayTeam(driverInfo.team2, transferInfo.date))
			or '',
		roleDisplay = hasAppendedRoleDisplay and (' as ' .. AnOrA.main{role}) or ''
	})

end

function DriverIntroduction:_droveOrWorked(isCurrentTense)
	local driverInfo = self.driverInfo
	local transferInfo = self.transferInfo
	local role = self.transferInfo.standardizedRole

	if driverInfo.type ~= TYPE_DRIVER and isCurrentTense then
		return 'driving for'
	elseif driverInfo.type ~= TYPE_DRIVER then
		return 'drove for'
	elseif not isCurrentTense then
		return 'drove for'
	elseif transferInfo.role == INACTIVE_ROLE and transferInfo.type == TRANSFER_STATUS_CURRENT then
		return 'on the inactive roster of'
	elseif self.options.showRole and role == 'streamer' or role == 'content creator' then
		return AnOrA.main{role} .. ' for'
	elseif self.options.showRole and String.isNotEmpty(role) then
		return 'playing as ' .. AnOrA.main{role} .. ' for'
	end

	return ' playing for'
end

function DriverIntroduction._displayTeam(team, date)
	team = team:gsub('_', ' ')

	if mw.ext.TeamTemplate.teamexists(team) then
		local rawTeam = mw.ext.TeamTemplate.raw(team, date)
		return ' [[' .. rawTeam.page .. '|' .. rawTeam.name .. ']]'
	end

	return ' [[' .. team .. ']]'
end

---@param text string|nil
---@param delimiter string?
---@param suffix boolean?
---@return string
function DriverIntroduction._addConcatText(text, delimiter, suffix)
	if not text then
		return ''
	end

	delimiter = delimiter or ' '

	return suffix and (text .. delimiter)
		or (delimiter .. text)
end

return DriverIntroduction
