---
-- @Liquipedia
-- page=Module:Infobox/Extension/PlacementStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MedalsTable = Lua.import('Module:Widget/MedalsTable')

local DEFAULT_TIERS = {'1', '2', '3'}
local DEFAULT_EXCLUDED_TIER_TYPES = {'Qualifier'}
local DATA_COLUMNS = {1, 2, 3, 'top3', 'total'}

local PlacementStats = {}

---@alias InfoboxPlacementStatsDataRow {[1]: integer, [2]: integer, [3]: integer, total: integer, top3: integer}
---@alias InfoboxPlacementStatsData table<string, InfoboxPlacementStatsDataRow>

---@param args table
---@return Widget?
function PlacementStats.run(args)
	args = args or {}

	local opponentType = args.opponentType or Opponent.team
	local opponent = args.participant or args.team or mw.title.getCurrentTitle().prefixedText

	local tiers = args.tiers or DEFAULT_TIERS
	local excludedTierTypes = args.excludedTierTypes or DEFAULT_EXCLUDED_TIER_TYPES

	local placementData = PlacementStats._fetchData(opponentType, opponent, tiers, excludedTierTypes)

	if placementData.total.total == 0 then
		return
	end

	return HtmlWidgets.Div{
		classes = {'fo-nttax-infobox', 'wiki-bordercolor-light'},
		children = {
			HtmlWidgets.Div{
				children = HtmlWidgets.Div{
					classes = {'infobox-header', 'wiki-backgroundcolor-light'},
					children = 'Placement Summary',
				},
			},
			MedalsTable{data = placementData, reducePadding = true, dataColumns = DATA_COLUMNS}
		}
	}
end

---@private
---@param opponentType string
---@param opponent string
---@param tiers string[]
---@param excludedTierTypes string[]
---@return InfoboxPlacementStatsData
function PlacementStats._fetchData(opponentType, opponent, tiers, excludedTierTypes)
	local baseConditions = PlacementStats._buildBaseConditions(opponentType, opponent, excludedTierTypes)
	local placementData = {total = PlacementStats._emptyDataSet()}

	Array.forEach(tiers, FnUtil.curry(FnUtil.curry(PlacementStats._fetchForTier, baseConditions), placementData))

	return placementData
end

---@private
---@return InfoboxPlacementStatsDataRow
function PlacementStats._emptyDataSet()
	return Table.map(DATA_COLUMNS, function(index, key) return key, 0 end) --[[@as InfoboxPlacementStatsDataRow]]
end

---@param opponentType string
---@param opponent string
---@param excludedTierTypes string[]
---@return ConditionTree
function PlacementStats._buildBaseConditions(opponentType, opponent, excludedTierTypes)
	local getTeamTemplates = function()
		local rawOpponentTemplate = TeamTemplate.getRawOrNil(opponent) or {}
		local opponentTemplate = rawOpponentTemplate.historicaltemplate or rawOpponentTemplate.templatename
		assert(opponentTemplate, 'Missing team template for team: ' .. opponent)
		return TeamTemplate.queryHistoricalNames(opponentTemplate)
	end

	return ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('placement'), Comparator.neq, ''),
		ConditionNode(ColumnName('opponenttype'), Comparator.eq, opponentType),
		ConditionUtil.noneOf(ColumnName('liquipediatiertype'), excludedTierTypes),
		opponentType ~= Opponent.team and ConditionNode(ColumnName('opponentname'), Comparator.eq, opponent)
			or ConditionUtil.anyOf(ColumnName('opponenttemplate'), getTeamTemplates()),
	}
end

---@param baseConditions ConditionTree
---@param placementData InfoboxPlacementStatsData
---@param tier string
function PlacementStats._fetchForTier(baseConditions, placementData, tier)
	local conditions = ConditionTree(BooleanOperator.all):add{
		baseConditions,
		ConditionNode(ColumnName('liquipediatier'), Comparator.eq, tier)
	}

	local queryData = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = 5000,
		conditions = tostring(conditions),
		query = 'placement, count::placement',
		groupby = 'placement asc'
	})

	if Logic.isEmpty(queryData) then
		return
	end

	placementData[tier] = PlacementStats._emptyDataSet()

	Array.forEach(queryData, function(placement)
		local count = tonumber(placement.count_placement)
		local place = tonumber(mw.text.split(placement.placement or '', '-', true)[1])

		placementData[tier].total = placementData[tier].total + count
		placementData.total.total = placementData.total.total + count

		if not place or place > 3 then
			return
		end

		placementData[tier][place] = (placementData[tier][place] or 0) + count
		placementData[tier].top3 = placementData[tier].top3 + count
		placementData.total[place] = (placementData.total[place] or 0) + count
		placementData.total.top3 = placementData.total.top3 + count
	end)
end

return PlacementStats
