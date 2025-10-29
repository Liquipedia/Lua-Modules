---
-- @Liquipedia
-- page=Module:TournamentsSummaryTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[

Generates the list of upcoming/ongoing/recent tournaments needed for the TournamentsMenu dropdown Extension

]]--

local TournamentsSummaryTable = {}

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')
local Variables = Lua.import('Module:Variables')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local SECONDS_PER_DAY = 86400

local _today = os.date('!%Y-%m-%d', os.time())

-- Default settings
-- overwritable via /Custom
TournamentsSummaryTable.tiers = {1, 2}
TournamentsSummaryTable.upcomingOffset = 10
TournamentsSummaryTable.completedOffset = 10
TournamentsSummaryTable.tierTypeExcluded = {}
TournamentsSummaryTable.statusExcluded = {'canceled', 'cancelled', 'postponed'}
TournamentsSummaryTable.disableLIS = false
TournamentsSummaryTable.defaultLimit = 7

---@enum conditionTypes
local conditionTypes = {
	upcoming = 1,
	ongoing = 2,
	recent = 3,
}

-- possibly needed in /Custom
TournamentsSummaryTable.upcomingType = conditionTypes.upcoming
TournamentsSummaryTable.ongoingType = conditionTypes.ongoing
TournamentsSummaryTable.recentType = conditionTypes.recent

local TYPE_TO_TITLE = {
	'Upcoming',
	'Ongoing',
	'Completed',
}

---@class tournamentsSummaryTableArgs
---@field limit number|string|nil
---@field upcoming boolean?
---@field ongoing boolean?
---@field recent boolean?
---@field sort string?
---@field order string?
---@field reverseDisplay boolean?
---@field title string?
---@field disableLIS boolean?
---@field completedOffset number?
---@field upcomingOffset number?
---@field tiers string?
---@field tierTypeExcluded string?

---@param args tournamentsSummaryTableArgs
---@return Html
function TournamentsSummaryTable.run(args)
	args = args or {}

	TournamentsSummaryTable._parseArgsToSettings(args)

	local type
	if args.upcoming == 'true' then
		type = TournamentsSummaryTable.upcomingType
	elseif args.ongoing == 'true' then
		type = TournamentsSummaryTable.ongoingType
	elseif args.recent == 'true' then
		type = TournamentsSummaryTable.recentType
	else
		error('No type parameter (upcoming, ongoing, recent) specified')
	end

	local title = mw.language.getContentLanguage():ucfirst(args.title or TYPE_TO_TITLE[type])
	local limit = args.limit and tonumber(args.limit) or TournamentsSummaryTable.defaultLimit
	local sort = args.sort or (type == TournamentsSummaryTable.recentType and 'end' or 'start')
	local order = args.order or (type == TournamentsSummaryTable.recentType and 'desc' or 'asc')

	local data = TournamentsSummaryTable._getTournaments(type, sort, order, limit)

	if Logic.readBool(args.reverseDisplay) then
		data = Array.reverse(data)
	end

	local wrapper = mw.html.create():wikitext('*' .. title)

	for _, tournamentData in ipairs(data) do
		wrapper:wikitext(TournamentsSummaryTable.row(tournamentData, type))
	end

	return wrapper
end

---@param args tournamentsSummaryTableArgs
function TournamentsSummaryTable._parseArgsToSettings(args)
	TournamentsSummaryTable.upcomingOffset = tonumber(args.upcomingOffset) or TournamentsSummaryTable.upcomingOffset

	TournamentsSummaryTable.completedOffset = tonumber(args.completedOffset) or TournamentsSummaryTable.completedOffset

	local parseTier = function(tier)
		tier = String.trim(tier)
		return tonumber(tier) or tier
	end

	TournamentsSummaryTable.tiers = args.tiers
		and Array.map(mw.text.split(args.tiers, ','), parseTier)
		or TournamentsSummaryTable.tiers

	TournamentsSummaryTable.disableLIS = Logic.readBool(args.disableLIS) or TournamentsSummaryTable.disableLIS

	TournamentsSummaryTable.tierTypeExcluded = args.tierTypeExcluded
		and Array.map(mw.text.split(args.tierTypeExcluded, ','), parseTier)
		or TournamentsSummaryTable.tierTypeExcluded
end

---@param conditionType conditionTypes
---@param sort string
---@param order string
---@param limit number
---@return table[]
function TournamentsSummaryTable._getTournaments(conditionType, sort, order, limit)
	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		query = 'pagename, name, tickername, icon, icondark, startdate, enddate, series',
		conditions = TournamentsSummaryTable._buildConditions(conditionType),
		order = sort .. 'date ' .. order .. ', liquipediatier asc, name asc',
		limit = limit,
	})

	if type(data) == 'table' and data[1] then
		return data
	end

	return {}
end

---@param type conditionTypes
---@return string
function TournamentsSummaryTable._buildConditions(type)
	local conditions = ConditionTree(BooleanOperator.all)
		:add(TournamentsSummaryTable._tierConditions())
		:add(TournamentsSummaryTable._tierTypeConditions())
		:add(TournamentsSummaryTable._statusConditions())
		:add(TournamentsSummaryTable.dateConditions(type))
		:add(TournamentsSummaryTable.additionalConditions(type))

	return conditions:toString()
end

---@return ConditionTree
function TournamentsSummaryTable._tierConditions()
	local conditions = ConditionTree(BooleanOperator.any)
	for _, tier in pairs(TournamentsSummaryTable.tiers) do
		conditions:add({ConditionNode(ColumnName('liquipediatier'), Comparator.eq, tier)})
	end

	return conditions
end

---@return ConditionTree|{}
function TournamentsSummaryTable._tierTypeConditions()
	if Table.isEmpty(TournamentsSummaryTable.tierTypeExcluded) then
		return {}
	end

	local conditions = ConditionTree(BooleanOperator.all)
	for _, tierType in pairs(TournamentsSummaryTable.tierTypeExcluded) do
		conditions:add({ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, tierType)})
	end

	return conditions
end

---@return ConditionTree|{}
function TournamentsSummaryTable._statusConditions()
	if Table.isEmpty(TournamentsSummaryTable.statusExcluded) then
		return {}
	end

	local conditions = ConditionTree(BooleanOperator.all)
	for _, status in pairs(TournamentsSummaryTable.statusExcluded) do
		conditions:add({ConditionNode(ColumnName('status'), Comparator.neq, status)})
	end

	return conditions
end

---@param type conditionTypes
---@return ConditionTree
function TournamentsSummaryTable.dateConditions(type)
	local conditions = ConditionTree(BooleanOperator.all)

	local currentTime = os.time()
	local upcomingThreshold = os.date('!%Y-%m-%d', currentTime
		+ TournamentsSummaryTable.upcomingOffset * SECONDS_PER_DAY)
	local completedThreshold = os.date('!%Y-%m-%d', currentTime
		- TournamentsSummaryTable.completedOffset * SECONDS_PER_DAY)

	if type == TournamentsSummaryTable.upcomingType then
		conditions
			:add({
				ConditionNode(ColumnName('startdate'), Comparator.lt, upcomingThreshold),
				ConditionNode(ColumnName('startdate'), Comparator.gt, _today),
			})
	elseif type == TournamentsSummaryTable.ongoingType then
		conditions
			:add({
				ConditionTree(BooleanOperator.any):add({
					ConditionNode(ColumnName('startdate'), Comparator.lt, _today),
					ConditionNode(ColumnName('startdate'), Comparator.eq, _today),
				}),
				ConditionTree(BooleanOperator.any):add({
					ConditionNode(ColumnName('enddate'), Comparator.gt, _today),
					ConditionNode(ColumnName('enddate'), Comparator.eq, _today),
				}),
				ConditionTree(BooleanOperator.any):add({
					ConditionNode(ColumnName('status'), Comparator.neq, 'finished'),
					ConditionNode(ColumnName('enddate'), Comparator.gt, _today),
				}),
			})
	elseif type == TournamentsSummaryTable.recentType then
		conditions
			:add({
				ConditionNode(ColumnName('enddate'), Comparator.gt, completedThreshold),
				ConditionNode(ColumnName('enddate'), Comparator.lt, _today),
			})
	end

	return conditions
end

function TournamentsSummaryTable.additionalConditions(type)
	return {}
end

---@param eventInformation table
---@param type conditionTypes
---@return string
function TournamentsSummaryTable.row(eventInformation, type)
	if type == TournamentsSummaryTable.upcomingType then
		Variables.varDefine('upcoming_' .. eventInformation.pagename, 1)
	end

	local displayName = String.isNotEmpty(eventInformation.tickername)
		and eventInformation.tickername
		or eventInformation.name

	local icon = ''
	if not TournamentsSummaryTable.disableLIS then
		if
			String.isNotEmpty(eventInformation.series) and
			TournamentsSummaryTable._lisTemplateExists(eventInformation.series:lower())
		then
			icon = eventInformation.series:lower()
		else
			icon = 'none'
		end
	end

	local iconFile = ''
	if String.isNotEmpty(eventInformation.icon) then
		local iconInput = string.gsub(eventInformation.icon, 'File:', '')
		if (mw.title.new('Media:' .. iconInput) or {}).exists then
			iconFile = 'File:' .. iconInput
		end
	end

	local iconDarkFile
	if String.isNotEmpty(eventInformation.icondark) then
		local iconInput = string.gsub(eventInformation.icondark, 'File:', '')
		if (mw.title.new('Media:' .. iconInput) or {}).exists then
			iconDarkFile = 'File:' .. iconInput
		end
	end

	local rowComponents = {
		'\n** ' .. eventInformation.pagename,
		displayName,
		'icon=' .. icon,
		'iconfile=' .. iconFile,
		'icondarkfile=' .. (iconDarkFile or iconFile),
		'startdate=' .. TournamentsSummaryTable._dateDisplay(eventInformation.startdate),
	}

	if eventInformation.startdate ~= eventInformation.enddate then
		table.insert(rowComponents, 'enddate=' .. TournamentsSummaryTable._dateDisplay(eventInformation.enddate))
	end

	return table.concat(rowComponents, ' | ')
end

---@param dateString string
---@return string
function TournamentsSummaryTable._dateDisplay(dateString)
	local year, month, day = dateString:match('(%d%d%d%d)-?(%d?%d?)-?(%d?%d?)$')
	local defaultYear, defaultMonth, defaultDay = DateExt.defaultDateTime:match('(%d%d%d%d)-?(%d?%d?)-?(%d?%d?)$')

	-- create time
	local date = os.time{
		year = Logic.emptyOr(year, defaultYear),
		month = Logic.emptyOr(month, defaultMonth),
		day = Logic.emptyOr(day, defaultDay),
		hour = 0
	}

	-- return date display
	return os.date('%b %d', date) --[[@as string]]
end

---@param series string
---@return boolean
function TournamentsSummaryTable._lisTemplateExists(series)
	local lis = Template.safeExpand(
		mw.getCurrentFrame(),
		'LeagueIconSmall/' .. series
	)

	return String.isNotEmpty(lis)
end

-- thin wrapper for adding manual upcoming rows (for adding events with unknown dates)
---@param args table
---@return string
function TournamentsSummaryTable.manualUpcomingRow(args)
	args = args or {}

	local pageName = args.pagename or args.link
	if String.isEmpty(pageName) then
		error('No pagename specified for manual upcoming row')
	end

	local eventInformation = {
		pagename = pageName,
		tickername = args.tickername or args.display or pageName,
		startdate = TournamentsSummaryTable._dateDisplay(args.estimated_start or args.startdate),
		enddate = TournamentsSummaryTable._dateDisplay(args.estimated_end or args.enddate),
		icon = args.icon,
		icondark = args.icondark,
		series = args.series,
	}

	local startdate = eventInformation.startdate

	if
		String.isNotEmpty(startdate) and _today < startdate and
		String.isEmpty(Variables.varDefault('upcoming_' .. pageName))
	then
		return TournamentsSummaryTable.row(eventInformation, TournamentsSummaryTable.upcomingType)
	end

	return ''
end

return Class.export(TournamentsSummaryTable, {exports = {'run'}})
