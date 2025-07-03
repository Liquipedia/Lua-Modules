---
-- @Liquipedia
-- page=Module:HiddenDataBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Game = Lua.import('Module:Game')
local Namespace = Lua.import('Module:Namespace')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TextSanitizer = Lua.import('Module:TextSanitizer')
local Tier = Lua.import('Module:Tier/Custom')
local Variables = Lua.import('Module:Variables')
local WarningBox = Lua.import('Module:WarningBox')

local HiddenDataBox = {}
local INVALID_TIER_WARNING = '${tierString} is not a known Liquipedia '
	.. '${tierMode}[[Category:Pages with invalid ${tierMode}]]'
local INVALID_PARENT = '${parent} is not a Liquipedia Tournament[[Category:Pages with invalid parent]]'
local DEFAULT_TIER_TYPE = 'general'

local Language = mw.getContentLanguage()

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

---Entry point
---@param args table?
---@return Html
function HiddenDataBox.run(args)
	args = args or {}
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
		})[1] or {}

		if Table.isEmpty(queryResult) and Namespace.isMain() then
			table.insert(warnings, String.interpolate(INVALID_PARENT, {parent = parent}))
		else
			local date = HiddenDataBox.cleanDate(args.date, args.sdate) or queryResult.startdate or
				Variables.varDefault('tournament_startdate') or HiddenDataBox.cleanDate(args.edate) or
				queryResult.enddate or Variables.varDefault('tournament_enddate')

			Array.forEach(HiddenDataBox._fetchPlacements(parent), function(placement)
				HiddenDataBox._setWikiVariablesFromPlacement(placement, date)
			end)
		end
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
	HiddenDataBox.checkAndAssign(
		'tournament_publishertier',
		Logic.readBool(args.highlighted) and 'true' or args.publishertier,
		queryResult.publishertier
	)

	HiddenDataBox.checkAndAssign('tournament_type', args.type, queryResult.type)
	HiddenDataBox.checkAndAssign('tournament_status', args.status, queryResult.status)
	HiddenDataBox.checkAndAssign('tournament_mode', args.mode, queryResult.mode)

	HiddenDataBox.checkAndAssign(
		'tournament_game',
		Game.toIdentifier{game = args.game, useDefault = false},
		queryResult.game
	)

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
	return String.nilIfEmpty(ReferenceCleaner.clean{input = primaryDate}) or
		String.nilIfEmpty(ReferenceCleaner.clean{input = secondaryDate})
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
---@return placement[]
function HiddenDataBox._fetchPlacements(parent)
	local placements = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = '[[pagename::' .. parent .. ']] AND [[opponenttype::!' .. Opponent.literal .. ']]',
		limit = 1000,
		query = 'opponentplayers, opponentname, opponenttype, extradata',
	})

	return Array.filter(placements, function(placement)
		return String.isNotEmpty(placement.opponentname) and placement.opponentname:lower() ~= 'tbd'
	end)
end

-- overridable so that wikis can add custom vars
---@param args table
---@param queryResult table
function HiddenDataBox.addCustomVariables(args, queryResult)
end

---@param placement placement
---@param date string
function HiddenDataBox._setWikiVariablesFromPlacement(placement, date)
	if Opponent.typeIsParty(placement.opponenttype) then
		---Opponent.resolve with syncPlayer enabled sets wiki variables as needed
		Opponent.resolve(Opponent.fromLpdbStruct(placement), date, {syncPlayer = true})
		return
	end

	-- TODO: An improvement would be called TeamCard module for this
	-- Would need a rework for the function that does it however
	local participant = placement.opponentname
	local participantResolved = mw.ext.TeamLiquidIntegration.resolve_redirect(participant)
	Table.iter.forEachPair(placement.opponentplayers or {}, function(key, value)
		if Table.isNotEmpty((placement.extradata or {}).opponentaliases) then
			Array.forEach(placement.extradata.opponentaliases, function(alias)
				HiddenDataBox._setWikiVariableForParticipantKey(alias, participantResolved, key, value)
			end)
		else
			HiddenDataBox._setWikiVariableForParticipantKey(participant, participantResolved, key, value)
		end
	end)
end

-- overridable so that wikis can add custom vars
---@param participant string
---@param participantResolved string
---@param key string
---@param value string|number
function HiddenDataBox._setWikiVariableForParticipantKey(participant, participantResolved, key, value)
	Variables.varDefine(participant .. '_' .. key, value)
	participant = Language:ucfirst(participant)
	Variables.varDefine(participant .. '_' .. key, value)
	if participant ~= participantResolved then
		Variables.varDefine(participantResolved .. '_' .. key, value)
	end
end

---Validates the provided tier, tierType pair
---@param tier string|number|nil
---@param tierType string?
---@return integer?, string?, string[]
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

return Class.export(HiddenDataBox, {exports = {'run'}})
