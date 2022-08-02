---
-- @Liquipedia
-- wiki=commons
-- page=Module:HiddenDataBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logc')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier')
local Variables = require('Module:Variables')
local WarningBox = require('Module:WarningBox')

local HiddenDataBox = {}
local INVALID_TIER_WARNING = '${tierString} is not a known Liquipedia '
	.. '${tierMode}[[Category:Pages with invalid ${tierMode}]]'
local INVALID_PARENT = '${parent} is not a Liquipedia Tournament'
local TIER_MODE_TYPES = 'types'
local TIER_MODE_TIERS = 'tiers'

---Entry point
function HiddenDataBox.run(args)
	args = args or {}
	args.participantGrabber = Logic.readBoolOrNil(args.participantGrabber) or true

	local warnings = {}
	local warning
	args.liquipediatier, warning
		= HiddenDataBox.validateTier(args.liquipediatier, TIER_MODE_TIERS)
	table.insert(warnings, warning)
	args.liquipediatiertype, warning
		= HiddenDataBox.validateTier(args.liquipediatiertype, TIER_MODE_TYPES)
	table.insert(warnings, warning)

	local parent = args.parent or args.tournament or tostring(mw.title.getCurrentTitle().basePageTitle)
	parent = parent:gsub(' ', '_')

	local queryResult = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. parent .. ']]',
		limit = 1,
	})
	queryResult = queryResult[1]

	if not queryResult then
		table.insert(warnings, String.interpolate(INVALID_PARENT, {parent = parent}))
		queryResult = {}
	elseif args.participantGrabber then
		local participants = HiddenDataBox._fetchParticipants(parent)

		Table.iter.forEachPair(participants, function (participant, players)
			-- TODO: An improvement would be called TeamCard module for this
			-- Would need a rework for the function that does it however
			local participantResolved = mw.ext.TeamLiquidIntegration.resolve_redirect(participant)

			Table.iter.forEachPair(players, function(key, value)
				HiddenDataBox.setWikiVariableForParticipantKey(participant, participantResolved, key, value)
			end)
		end)
	end

	HiddenDataBox.checkAndAssign('tournament_name', args.name, queryResult.name)
	HiddenDataBox.checkAndAssign('tournament_shortname', args.shortname, queryResult.shortname)
	HiddenDataBox.checkAndAssign('tournament_tickername', args.tickername, queryResult.tickername)
	HiddenDataBox.checkAndAssign('tournament_icon', args.icon, queryResult.icon)
	HiddenDataBox.checkAndAssign('tournament_icondark', args.icondark or args.icondarkmode, queryResult.icondark)
	HiddenDataBox.checkAndAssign('tournament_series', args.series, queryResult.series)

	HiddenDataBox.checkAndAssign('tournament_liquipediatier', args.liquipediatier, queryResult.liquipediatier)
	HiddenDataBox.checkAndAssign('tournament_liquipediatiertype', args.liquipediatiertype, queryResult.liquipediatiertype)

	HiddenDataBox.checkAndAssign('tournament_type', args.type, queryResult.type)
	HiddenDataBox.checkAndAssign('tournament_status', args.status, queryResult.status)
	HiddenDataBox.checkAndAssign('tournament_mode', args.mode, queryResult.mode)

	HiddenDataBox.checkAndAssign('tournament_game', args.game, queryResult.game)
	HiddenDataBox.checkAndAssign('tournament_parent', args.parent, parent)
	HiddenDataBox.checkAndAssign('tournament_parentname', args.parentname, queryResult.name)

	local startDate = HiddenDataBox.cleanDate(args.sdate, args.date)
	local endDate = HiddenDataBox.cleanDate(args.edate, args.date)
	HiddenDataBox.checkAndAssign('tournament_startdate', startDate, queryResult.startdate)
	HiddenDataBox.checkAndAssign('tournament_enddate', endDate, queryResult.enddate)

	HiddenDataBox.addCustomVariables(args, queryResult)

	return WarningBox.displayAll(warnings)
end

function HiddenDataBox.cleanDate(primaryDate, secondaryDate)
	return String.nilIfEmpty(ReferenceCleaner.clean(primaryDate)) or
		 	String.nilIfEmpty(ReferenceCleaner.clean(secondaryDate))
end

function HiddenDataBox.checkAndAssign(variableName, valueFromArgs, valueFromQuery)
	if String.isNotEmpty(valueFromArgs) then
		Variables.varDefine(variableName, valueFromArgs)
	elseif String.isEmpty(Variables.varDefault(variableName)) then
		Variables.varDefine(variableName, valueFromQuery or '')
	end
end

function HiddenDataBox._fetchParticipants(parent)
	local placements = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = '[[pagename::' .. parent .. ']]',
		limit = 1000,
		query = 'players, participant',
	})

	return Table.map(placements, function(_, placement)
		if String.isEmpty(placement.participant) or placement.participant:lower() == 'tbd' then
			return
		end

		return placement.participant, placement.players
	end)
end

-- overridable so that wikis can add custom vars
function HiddenDataBox.addCustomVariables(args, queryResult)
end

-- overridable so that wikis can add custom vars
function HiddenDataBox.setWikiVariableForParticipantKey(participant, participantResolved, key, value)
	Variables.varDefine(participant .. key, value)
	if participant ~= participantResolved then
		Variables.varDefine(participantResolved .. key, value)
	end
end

-- overridable so that wikis can adjust according to their tier system
function HiddenDataBox.validateTier(tierString, tierMode)
	if String.isEmpty(tierString) then
		return
	end
	local warning
	local tierValue = (Tier.text[tierMode] and
						Tier.text[tierMode][tierString:lower()]) or
					 	Tier.text[tierString]

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

	-- For types we want to normalized value
	-- For tiers we want to return the input
	tierValue = tierMode == TIER_MODE_TYPES and tierValue or tierString

	return tierValue, warning
end

return Class.export(HiddenDataBox)
