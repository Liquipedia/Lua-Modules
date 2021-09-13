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

local HDB = {}

function HDB.run(args)
	local tournament = args.tournament or mw.title.getCurrentTitle().prefixedText
	local parent = tournament:gsub('/.-$', ''):gsub(' ', '_')

	local queryResult = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. parent .. ']]',
		limit = 1,
		order = 'pagename asc',
	})
	queryResult = queryResult[1] or {}

	local startDate = HDB:cleanDate(args.sdate, args.date)
	local endDate = HDB:cleanDate(args.edate, args.date)
	HDB:checkAndAssign('tournament_startdate', startDate, queryResult.startdate)
	HDB:checkAndAssign('tournament_enddate', endDate, queryResult.enddate)

	HDB:checkAndAssign('tournament_name', args.name, queryResult.name)
	HDB:checkAndAssign('tournament_series', args.series, queryResult.series)
	HDB:checkAndAssign('tournament_shortname', args.shortname, queryResult.shortname)
	HDB:checkAndAssign('tournament_tickername', args.tickername, queryResult.tickername)
	HDB:checkAndAssign('tournament_icon', args.icon, queryResult.icon)
	HDB:checkAndAssign('tournament_icondark', args.icondark or args.icondarkmode, queryResult.icondark)
	HDB:checkAndAssign('tournament_liquipediatier', args.liquipediatier, queryResult.liquipediatier)
	HDB:checkAndAssign('tournament_liquipediatiertype', args.liquipediatiertype, queryResult.liquipediatiertype)
	HDB:checkAndAssign('tournament_type', args.type, queryResult.type)
	HDB:checkAndAssign('tournament_status', args.status, queryResult.status)
	HDB:checkAndAssign('tournament_game', args.game, queryResult.game)
	HDB:checkAndAssign('tournament_parent', args.parent, parent)
	HDB:checkAndAssign('tournament_parentname', args.parentname, queryResult.name)

	HDB:addCustomVariables(args, queryResult)
end

function HDB:cleanDate(primaryDate, secondaryDate)
	local date
	if (not String.isEmpty(primaryDate)) and primaryDate:lower() ~= 'tba' and primaryDate:lower() ~= 'tbd' then
		date = primaryDate:gsub('%-??', '-01'):gsub('%-XX', '-01')
	elseif (not String.isEmpty(secondaryDate)) and secondaryDate:lower() ~= 'tba' and secondaryDate:lower() ~= 'tbd' then
		date = secondaryDate:gsub('%-??', '-01'):gsub('%-XX', '-01')
	end

	return date
end

function HDB:checkAndAssign(variableName, valueFromArgs, valueFromQuery)
	if not String.isEmpty(valueFromArgs) then
		Variables.varDefine(variableName, valueFromArgs)
	elseif String.isEmpty(Variables.varDefault(variableName)) then
		Variables.varDefine(variableName, valueFromQuery or '')
	end
end

--overridable so that wikis can add custom vars
function HDB:addCustomVariables() end

return Class.export(HDB)
