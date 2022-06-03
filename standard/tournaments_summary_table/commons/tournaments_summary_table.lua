---
-- @Liquipedia
-- wiki=commons
-- page=Module:TournamentsSummaryTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[

Generates the list of upcoming/ongoing/recent tournaments needed for the TournamentsMenu dropdown Extension

]]--

local TournamentsSummaryTable = {}

local Class = require('Module:Class')
local Table = require('Module:Table')
local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Template = require('Module:Template')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local _SECONDS_PER_DAY = 86400

local _today = os.date("!%Y-%m-%d", os.time())

-- Default settings
-- overwritable via /Custom
TournamentsSummaryTable.tiers = {1, 2}
TournamentsSummaryTable.upcomingOffset = _SECONDS_PER_DAY * 10
TournamentsSummaryTable.completedOffset = _SECONDS_PER_DAY * 10
TournamentsSummaryTable.tierTypeExcluded = {}
TournamentsSummaryTable.statusExcluded = {'canceled', 'cancelled', 'postponed'}
TournamentsSummaryTable.disableLIS = false
TournamentsSummaryTable.defaultLimit = 7

-- possibly needed in /Custom
TournamentsSummaryTable.upcomingType = 1
TournamentsSummaryTable.ongoingType = 2
TournamentsSummaryTable.recentType = 3

local _TYPE_TO_TITLE = {
	'Upcoming',
	'Ongoing',
	'Completed',
}

function TournamentsSummaryTable.run(args)
	args = args or {}

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

	local title = mw.language.getContentLanguage():ucfirst(args.title or _TYPE_TO_TITLE[type])
	local limit = args.limit and tonumber(args.limit) or TournamentsSummaryTable.defaultLimit
	local sort = args.sort or 'start'
	local order = args.order or 'asc'

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

function TournamentsSummaryTable._buildConditions(type)
	local conditions = ConditionTree(BooleanOperator.all)
		:add(TournamentsSummaryTable._tierConditions())
		:add(TournamentsSummaryTable._tierTypeConditions())
		:add(TournamentsSummaryTable._statusConditions())
		:add(TournamentsSummaryTable.dateConditions(type))
		:add(TournamentsSummaryTable.additionalConditions(type))

	return conditions:toString()
end

function TournamentsSummaryTable._tierConditions()
	local conditions = ConditionTree(BooleanOperator.any)
	for _, tier in pairs(TournamentsSummaryTable.tiers) do
		conditions:add({ConditionNode(ColumnName('liquipediatier'), Comparator.eq, tier)})
	end

	return conditions
end

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

function TournamentsSummaryTable.dateConditions(type)
	local conditions = ConditionTree(BooleanOperator.all)

	local currentTime = os.time()
	local upcomingThreshold = os.date("!%Y-%m-%d", currentTime + TournamentsSummaryTable.upcomingOffset)
	local completedThreshold = os.date("!%Y-%m-%d", currentTime - TournamentsSummaryTable.completedOffset)

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
		if mw.title.new('Media:' .. iconInput).exists then
			iconFile = 'File:' .. iconInput
		end
	end

	local iconDarkFile
	if String.isNotEmpty(eventInformation.icondark) then
		local iconInput = string.gsub(eventInformation.icondark, 'File:', '')
		if mw.title.new('Media:' .. iconInput).exists then
			iconDarkFile = 'File:' .. iconInput
		end
	end

	local rowComponents = {
		'\n** ' .. eventInformation.pagename,
		displayName,
		'startdate=' .. TournamentsSummaryTable._dateDisplay(eventInformation.startdate),
		'enddate=' .. TournamentsSummaryTable._dateDisplay(eventInformation.enddate),
		'icon=' .. icon,
		'iconfile=' .. iconFile,
		'icondarkfile=' .. (iconDarkFile or iconFile),
	}

	return table.concat(rowComponents, ' | ')
end

function TournamentsSummaryTable._dateDisplay(dateString)
	local year, month, day = dateString:match("(%d%d%d%d)-?(%d?%d?)-?(%d?%d?)$")
	-- fallback
	if String.isEmpty(year) then
		year = 1970
	end
	-- defaults
	if String.isEmpty(month) then
		month = 1
	end
	if String.isEmpty(day) then
		day = 1
	end

	-- create time
	local date = os.time{year=year, month=month, day=day, hour=0}

	-- return date display
	return os.date('%b %d', date)
end

function TournamentsSummaryTable._lisTemplateExists(series)
	local lis = Template.safeExpand(
		mw.getCurrentFrame(),
		'LeagueIconSmall/' .. series
	)

	return String.isNotEmpty(lis)
end

-- thin wrapper for adding manual upcoming rows (for adding events with unknown dates)
function TournamentsSummaryTable.manualUpcomingRow(args)
	args = args or {}

	local pageName = args.pagename or args.link
	if String.isEmpty(pageName) then
		error('No pagename specified for manual upcoming row')
	end

	local eventInformation = {
		pagename  = pageName,
		tickername = args.tickername  or args.display or pageName,
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

return Class.export(TournamentsSummaryTable)
