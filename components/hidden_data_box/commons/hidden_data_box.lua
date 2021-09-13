---
-- @Liquipedia
-- wiki=commons
-- page=Module:HiddenDataBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Variables = require('Module:Variables')
local String = require('Module:StringUtils')
local ReferenceCleaner = require('Module:ReferenceCleaner')

local HiddenDataBox = {}

function HiddenDataBox.run(args)
	local tournament = args.tournament or mw.title.getCurrentTitle().prefixedText
	local parent = tournament:gsub('/.-$', ''):gsub(' ', '_')

	local queryResult = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. parent .. ']]',
		limit = 1,
		order = 'pagename asc',
	})
	queryResult = queryResult[1] or {}

	local startDate = HiddenDataBox:cleanDate(args.sdate, args.date)
	local endDate = HiddenDataBox:cleanDate(args.edate, args.date)
	HiddenDataBox:checkAndAssign('tournament_startdate', startDate, queryResult.startdate)
	HiddenDataBox:checkAndAssign('tournament_enddate', endDate, queryResult.enddate)

	HiddenDataBox:checkAndAssign('tournament_name', args.name, queryResult.name)
	HiddenDataBox:checkAndAssign('tournament_series', args.series, queryResult.series)
	HiddenDataBox:checkAndAssign('tournament_shortname', args.shortname, queryResult.shortname)
	HiddenDataBox:checkAndAssign('tournament_tickername', args.tickername, queryResult.tickername)
	HiddenDataBox:checkAndAssign('tournament_icon', args.icon, queryResult.icon)
	HiddenDataBox:checkAndAssign('tournament_icondark', args.icondark or args.icondarkmode, queryResult.icondark)
	HiddenDataBox:checkAndAssign('tournament_liquipediatier', args.liquipediatier, queryResult.liquipediatier)
	HiddenDataBox:checkAndAssign('tournament_liquipediatiertype', args.liquipediatiertype, queryResult.liquipediatiertype)
	HiddenDataBox:checkAndAssign('tournament_type', args.type, queryResult.type)
	HiddenDataBox:checkAndAssign('tournament_status', args.status, queryResult.status)
	HiddenDataBox:checkAndAssign('tournament_game', args.game, queryResult.game)
	HiddenDataBox:checkAndAssign('tournament_parent', args.parent, parent)
	HiddenDataBox:checkAndAssign('tournament_parentname', args.parentname, queryResult.name)

	HiddenDataBox:addCustomVariables(args, queryResult)
end

function HiddenDataBox:cleanDate(primaryDate, secondaryDate)
	local date
	if (not String.isEmpty(primaryDate)) and primaryDate:lower() ~= 'tba' and primaryDate:lower() ~= 'tbd' then
		date = ReferenceCleaner.clean(primaryDate)
	elseif (not String.isEmpty(secondaryDate)) and secondaryDate:lower() ~= 'tba' and secondaryDate:lower() ~= 'tbd' then
		date = ReferenceCleaner.clean(secondaryDate)
	end

	return date
end

function HiddenDataBox:checkAndAssign(variableName, valueFromArgs, valueFromQuery)
	if not String.isEmpty(valueFromArgs) then
		Variables.varDefine(variableName, valueFromArgs)
	elseif String.isEmpty(Variables.varDefault(variableName)) then
		Variables.varDefine(variableName, valueFromQuery or '')
	end
end

--overridable so that wikis can add custom vars
function HiddenDataBox:addCustomVariables() end

return Class.export(HiddenDataBox)
