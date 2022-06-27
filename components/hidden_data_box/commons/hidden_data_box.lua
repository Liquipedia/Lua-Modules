---
-- @Liquipedia
-- wiki=commons
-- page=Module:HiddenDataBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')
local Tier = require('Module:Tier')
local Variables = require('Module:Variables')
local WarningBox = require('Module:WarningBox')

local HiddenDataBox = {}
local INVALID_TIER_WARNING = '${tierString} is not a known Liquipedia '
	.. '${tierMode}[[Category:Pages with invalid ${tierMode}]]'
local TIER_MODE_TYPES = 'types'
local TIER_MODE_TIERS = 'tiers'

function HiddenDataBox.run(args)
	args = args or {}

	local warnings = {}
	local warning
	args.liquipediatier, warning
		= HiddenDataBox.validateTier(args.liquipediatier, TIER_MODE_TIERS)
	table.insert(warnings, warning)
	args.liquipediatiertype, warning
		= HiddenDataBox.validateTier(args.liquipediatiertype, TIER_MODE_TYPES)
	table.insert(warnings, warning)

	local parent = args.tournament or tostring(mw.title.getCurrentTitle().basePageTitle)
	parent = parent:gsub(' ', '_')

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

	return WarningBox.displayAll(warnings)
end

function HiddenDataBox:cleanDate(primaryDate, secondaryDate)
	local date = ReferenceCleaner.clean(primaryDate)
	if date == '' then
		date = ReferenceCleaner.clean(secondaryDate)
		if date == '' then
			return nil
		end
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

-- overridable so that wikis can add custom vars
function HiddenDataBox:addCustomVariables() end

-- overridable so that wikis can adjust
-- according to their tier system
function HiddenDataBox.validateTier(tierString, tierMode)
	if String.isEmpty(tierString) then
		return nil, nil
	end
	local warning
	local tierValue = Tier.text[tierMode][tierString:lower()]
	if not tierValue then
		tierValue = tierString
		warning = String.interpolate(
			INVALID_TIER_WARNING,
			{
				tierString = tierString,
				tierMode = tierMode == TIER_MODE_TYPES and 'Tier Type' or 'Tier',
			}
		)
	end

	tierValue = tierMode == TIER_MODE_TYPES and tierValue or tierString

	return tierValue, warning
end

return Class.export(HiddenDataBox)
