---
-- @Liquipedia
-- wiki=fortnite
-- page=Module:ResultsTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier')

local ResultsTable = Lua.import('Module:ResultsTable', {requireDevIfEnabled = true})
local AwardsTable = Lua.import('Module:ResultsTable/Award', {requireDevIfEnabled = true})

local Opponent = require('Module:OpponentLibraries').Opponent

local UNDEFINED_TIER = 'undefined'

local CustomResultsTable = {}

-- Template entry point
function CustomResultsTable.results(args)
	local resultsTable = ResultsTable(args)

	-- overwrite functions
	resultsTable.tierDisplay = CustomResultsTable.tierDisplay
	resultsTable.processLegacyVsData = CustomResultsTable.processLegacyVsData
	resultsTable.processVsData = CustomResultsTable.processVsData

	return resultsTable:create():build()
end

function CustomResultsTable.awards(args)
	local awardsTable = AwardsTable(args)

	-- overwrite functions
	awardsTable.tierDisplay = CustomResultsTable.tierDisplay

	return awardsTable:create():build()
end

-- to be replaced with a call to Module:Tier/Utils once that module is on git
function CustomResultsTable:tierDisplay(placement)
	local tierDisplay = Tier.text.tiers[string.lower(placement.liquipediatier or '')] or UNDEFINED_TIER

	tierDisplay = Page.makeInternalLink(
		{},
		tierDisplay,
		tierDisplay .. ' Tournaments'
	)

	local tierTypeDisplay = Tier.text.typesShort[(placement.liquipediatiertype or ''):lower()]

	local sortValue = placement.liquipediatier .. (tierTypeDisplay or '')

	if not tierTypeDisplay then
		return tierDisplay, sortValue
	end

	return tierDisplay .. ' (' .. tierTypeDisplay .. ')', sortValue
end

function CustomResultsTable:processLegacyVsData(placement)
	if Table.isEmpty(placement.lastvsdata) then
		local opponent = (placement.extradata or {}).vsOpponent or {}
		placement.lastvsdata = Table.merge(
			Opponent.toLpdbStruct(opponent or {}),
			{groupscore = placement.groupscore, score = placement.lastvsscore}
		)
	end

	return placement
end

function CustomResultsTable:processVsData(placement)
	local lastVs = placement.lastvsdata

	if String.isNotEmpty(lastVs.groupscore) then
		return placement.groupscore, Abbreviation.make('Grp S.', 'Group Stage')
	end

	-- return empty strings for non group scores since it is a BattleRoyale wiki
	return '', ''
end

return Class.export(CustomResultsTable)
