---
-- @Liquipedia
-- page=Module:Infobox/Extension/PlacementStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Medals = Lua.import('Module:Medals')
local Opponent = Lua.import('Module:Opponent/Custom')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Tier = Lua.import('Module:Tier/Custom')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ConditionUtil = Condition.Util

local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_TIERS = {'1', '2', '3'}
local DEFAULT_EXCLUDED_TIER_TYPES = {'Qualifier'}

local PlacementStats = {}

---@class InfoboxPlacementStatsData
---@field tiers {top3: integer, all: integer, placement: {[1]: integer, [2]: integer, [3]: integer}}[]
---@field totals {top3: integer, all: integer, placement: {[1]: integer, [2]: integer, [3]: integer}}}

---Entry Point: Queries placement statistics and builds a table for display of them below infoboxes
---@param args table
---@return Renderable
function PlacementStats.run(args)
	args = args or {}

	local opponentType = args.opponentType or Opponent.team
	local opponent = args.participant or args.team or mw.title.getCurrentTitle().prefixedText

	local tiers = args.tiers or DEFAULT_TIERS
	local excludedTierTypes = args.excludedTierTypes or DEFAULT_EXCLUDED_TIER_TYPES

	local placementData = PlacementStats._fetchData(opponentType, opponent, tiers, excludedTierTypes)

	if placementData.totals.all == 0 then
		return ''
	end

	return PlacementStats._buildTable(placementData, tiers)
end

---Query the count values
---@param opponentType OpponentType
---@param opponent string
---@param tiers string[]
---@param excludedTierTypes string[]
---@return InfoboxPlacementStatsData
function PlacementStats._fetchData(opponentType, opponent, tiers, excludedTierTypes)
	local baseConditions = PlacementStats._buildConditions(opponentType, opponent, excludedTierTypes)
	local placementData = {tiers = {}, totals = {top3 = 0, all = 0, placement = {}}}

	for _, tier in ipairs(tiers) do
		PlacementStats._fetchForTier(tier, baseConditions, placementData)
	end

	return placementData
end

---Builds the base conditions for the queries
---@param opponentType OpponentType
---@param opponent string
---@param excludedTierTypes string[]
---@return ConditionTree
function PlacementStats._buildConditions(opponentType, opponent, excludedTierTypes)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode('placement', Comparator.neq, ''),
		ConditionNode('opponenttype', Comparator.eq, opponentType),
	}

	conditions:add(ConditionUtil.noneOf('liquipediatiertype', excludedTierTypes))

	if opponentType ~= Opponent.team then
		conditions:add(ConditionNode('opponentname', Comparator.eq, opponent))
	else
		local rawOpponentTemplate = TeamTemplate.getRawOrNil(opponent) or {}
		local opponentTemplate = rawOpponentTemplate.historicaltemplate or rawOpponentTemplate.templatename
		if not opponentTemplate then
			error(TeamTemplate.noTeamMessage(opponent))
		end

		local teamTemplates = TeamTemplate.queryHistoricalNames(opponentTemplate)
		conditions:add(ConditionUtil.anyOf('opponenttemplate', teamTemplates))
	end

	return conditions
end

---Fetches the placement count values for a given tier
---@param tier string
---@param baseConditions ConditionTree
---@param placementData InfoboxPlacementStatsData
function PlacementStats._fetchForTier(tier, baseConditions, placementData)
	placementData.tiers[tier] = {top3 = 0, all = 0, placement = {}}

	local queryData = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = 5000,
		conditions = tostring(ConditionTree(BooleanOperator.all):add{
			baseConditions,
			ConditionNode('liquipediatier', Comparator.eq, tier),
		}),
		query = 'placement, count::placement',
		groupby = 'placement asc'
	})

	for _, placement in pairs(queryData) do
		local count = tonumber(placement.count_placement)
		local place = tonumber(mw.text.split(placement.placement or '', '-', true)[1])

		placementData.tiers[tier].all = placementData.tiers[tier].all + count
		placementData.totals.all = placementData.totals.all + count
		if place and place <= 3 then
			placementData.tiers[tier].placement[place] = (placementData.tiers[tier].placement[place] or 0) + count
			placementData.tiers[tier].top3 = placementData.tiers[tier].top3 + count
			placementData.totals.placement[place] = (placementData.totals.placement[place] or 0) + count
			placementData.totals.top3 = placementData.totals.top3 + count
		end
	end
end

---Builds the display
---@param placementData InfoboxPlacementStatsData
---@param tiers string[]
---@return VNode
function PlacementStats._buildTable(placementData, tiers)
	local display = Html.Table{
		classes = {'wikitable', 'sortable', 'wikitable-striped', 'wikitable-bordered'},
		css = {['text-align'] = 'center'},
		children = WidgetUtil.collect(
			PlacementStats._header(),
			Array.map(tiers, function (tier)
				return PlacementStats._buildRow(placementData.tiers[tier], tier)
			end),
			PlacementStats._buildBottom(placementData)
		)
	}

	local infoboxHeader = Html.Div{
		children = Html.Div{
			classes = {'infobox-header', 'wiki-backgroundcolor-light'},
			children = 'Placement Summary',
		}
	}

	return Html.Div{
		classes = {'fo-nttax-infobox-wrapper'},
		children = Html.Div{
			classes = {'fo-nttax-infobox', 'wiki-bordercolor-light'},
			children = {
				infoboxHeader,
				display,
			}
		}
	}
end

---Builds the header
---@return VNode
function PlacementStats._header()
	return Html.Tr{children = {
		Html.Th{
			children = 'Tier',
			css = {
				['text-align'] = 'left',
				width = '100%',
			}
		},
		Html.Th{children = Medals.display{medal = 1}},
		Html.Th{children = Medals.display{medal = 2}},
		Html.Th{children = Medals.display{medal = 3}},
		Html.Th{children = Html.Abbr{children = 'Top3', title = 'Total of top 3'}},
		Html.Th{children = 'All'},
	}}
end

---Builds a row
---@param placementData {top3: integer, all: integer, placement: {[1]: integer, [2]: integer, [3]: integer}}
---@param tier string
---@return VNode?
function PlacementStats._buildRow(placementData, tier)
	if placementData.all == 0 then
		return
	end

	return Html.Tr{children = WidgetUtil.collect(
		Html.Td{
			css = {['text-align'] = 'left'},
			children = Tier.display(tier, nil, {link = true}),
		},
		Array.mapRange(1, 3, function (place)
			return Html.Td{children = placementData.placement[place]}
		end),
		Html.Td{
			children = placementData.top3,
			css = {['font-weight'] = 'bold'},
		},
		Html.Td{children = placementData.all}
	)}
end

---Builds the bottom row
---@param placementData InfoboxPlacementStatsData
---@return VNode
function PlacementStats._buildBottom(placementData)
	return Html.Tr{children = WidgetUtil.collect(
		Html.Th{
			css = {['text-align'] = 'left'},
			children = 'Total',
		},
		Array.mapRange(1, 3, function (place)
			return Html.Th{children = placementData.totals.placement[place]}
		end),
		Html.Th{children = placementData.totals.top3},
		Html.Th{children = placementData.totals.all}
	)}
end

return Class.export(PlacementStats, {frameOnly = true, exports = {'run'}})
