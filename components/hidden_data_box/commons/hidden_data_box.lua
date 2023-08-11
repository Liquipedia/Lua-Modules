---
-- @Liquipedia
-- wiki=commons
-- page=Module:HiddenDataBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TextSanitizer = require('Module:TextSanitizer')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')
local WarningBox = require('Module:WarningBox')

local HiddenDataBox = {}
local INVALID_TIER_WARNING = '${tierString} is not a known Liquipedia '
	.. '${tierMode}[[Category:Pages with invalid ${tierMode}]]'
local INVALID_PARENT = '${parent} is not a Liquipedia Tournament[[Category:Pages with invalid parent]]'
local DEFAULT_TIER_TYPE = 'general'

---Entry point
---@param args table?
---@return string
function HiddenDataBox.run(args)
	args = args or {}
	args.participantGrabber = Logic.nilOr(Logic.readBoolOrNil(args.participantGrabber), true)
	local doQuery = not Logic.readBool(args.noQuery)

	local warnings
	args.liquipediatier, args.liquipediatiertype, warnings
		= HiddenDataBox.validateTier(args.liquipediatier, args.liquipediatiertype)

	local parent = args.parent or args.tournament or tostring(mw.title.getCurrentTitle().basePageTitle)
	parent = parent:gsub(' ', '_')

	local queryResult = {}
	if doQuery then
		queryResult = mw.ext.LiquipediaDB.lpdb('tournament', {
			conditions = '[[pagename::' .. parent .. ']]',
			limit = 1,
		})

		if not queryResult[1] and Namespace.isMain() then
			table.insert(warnings, String.interpolate(INVALID_PARENT, {parent = parent}))
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

		queryResult = queryResult[1] or {}
	end

	HiddenDataBox.checkAndAssign('tournament_name', TextSanitizer.stripHTML(args.name), queryResult.name)
	HiddenDataBox.checkAndAssign(
		'tournament_shortname',
		TextSanitizer.stripHTML(args.shortname),
		queryResult.shortname
	)
	HiddenDataBox.checkAndAssign(
		'tournament_tickername',
		TextSanitizer.stripHTML(args.tickername),
		queryResult.tickername
	)
	HiddenDataBox.checkAndAssign('tournament_icon', args.icon, queryResult.icon)
	HiddenDataBox.checkAndAssign('tournament_icondark', args.icondark or args.icondarkmode, queryResult.icondark)
	HiddenDataBox.checkAndAssign('tournament_series', args.series, queryResult.series)

	HiddenDataBox.checkAndAssign('tournament_liquipediatier', args.liquipediatier, queryResult.liquipediatier)
	HiddenDataBox.checkAndAssign('tournament_liquipediatiertype', args.liquipediatiertype, queryResult.liquipediatiertype)
	HiddenDataBox.checkAndAssign('tournament_publishertier', args.publishertier, queryResult.publishertier)

	HiddenDataBox.checkAndAssign('tournament_type', args.type, queryResult.type)
	HiddenDataBox.checkAndAssign('tournament_status', args.status, queryResult.status)
	HiddenDataBox.checkAndAssign('tournament_mode', args.mode, queryResult.mode)

	HiddenDataBox.checkAndAssign('tournament_game', args.game, queryResult.game)
	HiddenDataBox.checkAndAssign('tournament_parent', parent)
	HiddenDataBox.checkAndAssign('tournament_parentname', args.parentname, queryResult.name)

	local startDate = HiddenDataBox.cleanDate(args.sdate, args.date)
	local endDate = HiddenDataBox.cleanDate(args.edate, args.date)
	HiddenDataBox.checkAndAssign('tournament_startdate', startDate, queryResult.startdate)
	HiddenDataBox.checkAndAssign('tournament_enddate', endDate, queryResult.enddate)

	HiddenDataBox.addCustomVariables(args, queryResult)

	return WarningBox.displayAll(warnings)
end

---Cleans date input
---@param primaryDate string?
---@param secondaryDate string?
---@return string?
function HiddenDataBox.cleanDate(primaryDate, secondaryDate)
	return String.nilIfEmpty(ReferenceCleaner.clean(primaryDate)) or
		String.nilIfEmpty(ReferenceCleaner.clean(secondaryDate))
end

---Assigns the wiki Variables according to given input, wiki variable and queryResults
---@param variableName string
---@param valueFromArgs string|number|nil
---@param valueFromQuery string|number|nil
function HiddenDataBox.checkAndAssign(variableName, valueFromArgs, valueFromQuery)
	if Logic.isNotEmpty(valueFromArgs) then
		Variables.varDefine(variableName, valueFromArgs)
	elseif String.isEmpty(Variables.varDefault(variableName)) then
		Variables.varDefine(variableName, valueFromQuery or '')
	end
end

---Fetches participant information from the parent page
---@param parent string
---@return {[string]: {[string]: string}}
function HiddenDataBox._fetchParticipants(parent)
	local placements = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = '[[pagename::' .. parent .. ']]',
		limit = 1000,
		query = 'players, participant',
	})

	return
		Table.map(
			Table.filter(placements, function(placement)
				return String.isNotEmpty(placement.participant) and placement.participant:lower() ~= 'tbd'
			end),
			function(_, placement)
				return placement.participant, placement.players
			end
		)
end

-- overridable so that wikis can add custom vars
---@param args table
---@param queryResult table
function HiddenDataBox.addCustomVariables(args, queryResult)
end

-- overridable so that wikis can add custom vars
---@param participant string
---@param participantResolved string
---@param key string
---@param value string|number
function HiddenDataBox.setWikiVariableForParticipantKey(participant, participantResolved, key, value)
	Variables.varDefine(participant .. '_' .. key, value)
	if participant ~= participantResolved then
		Variables.varDefine(participantResolved .. '_' .. key, value)
	end
end

---Validates the provided tier, tierType pair
---@param tier string|number|nil
---@param tierType string?
---@return string|number|nil, string?, string[]
function HiddenDataBox.validateTier(tier, tierType)
	local warnings = {}

	if not tier and not tierType then
		return nil, nil, warnings
	end

	local tierValue, tierTypeValue = Tier.toValue(tier, tierType)

	if tier and not tierValue then
		table.insert(warnings, String.interpolate(INVALID_TIER_WARNING, {tierString = tier, tierMode = 'Tier'}))
	end

	if tierType and tierType:lower() ~= DEFAULT_TIER_TYPE and not tierTypeValue then
		table.insert(warnings, String.interpolate(INVALID_TIER_WARNING, {tierString = tierType, tierMode = 'Tiertype'}))
	end

	return tierValue, tierTypeValue, warnings
end

return Class.export(HiddenDataBox)
