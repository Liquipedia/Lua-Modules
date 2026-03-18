---
-- @Liquipedia
-- page=Module:ResultsTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local ResultsTable = Lua.import('Module:ResultsTable')
local AwardsTable = Lua.import('Module:ResultsTable/Award')

local Opponent = Lua.import('Module:Opponent/Custom')

local CustomResultsTable = {}

-- Template entry point
---@param args table
---@return Widget
function CustomResultsTable.results(args)
	local resultsTable = ResultsTable(args)

	-- overwrite functions
	resultsTable.processLegacyVsData = CustomResultsTable.processLegacyVsData
	resultsTable.processVsData = CustomResultsTable.processVsData

	return resultsTable:create():build()
end

---@param args table
---@return Widget
function CustomResultsTable.awards(args)
	return AwardsTable(args):create():build()
end

---Adjusts the lastvsdata handling for fortnite
---@param placement table
---@return table
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

---Adjusts the lastvs display for fortnite
---@param placement table
---@return string, string
function CustomResultsTable:processVsData(placement)
	local lastVs = placement.lastvsdata

	if String.isNotEmpty(lastVs.groupscore) then
		return placement.groupscore, Abbreviation.make{text = 'Grp S.', title = 'Group Stage'}
	end

	-- return empty strings for non group scores since it is a BattleRoyale wiki
	return '', ''
end

return Class.export(CustomResultsTable, {exports = {'results', 'awards'}})
