---
-- @Liquipedia
-- wiki=commons
-- page=Module:InfoboxPlacementStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Medals = require('Module:Medals')
local Team = require('Module:Team')
local Tier = require('Module:Tier/Custom')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local DEFAULT_TIERS = {'1', '2', '3'}
local DEFAULT_EXCLUDED_TIER_TYPES = {'Qualifier'}

local PlacementStats = {}

---@class InfoboxPlacementStatsData
---@field tiers {top3: integer, all: integer, placement: {[1]: integer, [2]: integer, [3]: integer}}[]
---@field totals {top3: integer, all: integer, placement: {[1]: integer, [2]: integer, [3]: integer}}}

---Entry Point: Queries placement statistics and builds a table for display of them below infoboxes
---@param args table
---@return Html|string
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
---@param opponentType string
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
---@param opponentType string
---@param opponent string
---@param excludedTierTypes string[]
---@return string
function PlacementStats._buildConditions(opponentType, opponent, excludedTierTypes)
	local conditions = {
		'[[placement::!]]',
		'[[opponenttype::' .. opponentType .. ']]'
	}

	for _, excludedTierType in pairs(excludedTierTypes) do
		table.insert(conditions, '[[liquipediatiertype::!' .. excludedTierType .. ']]')
	end

	if opponentType ~= Opponent.team then
		table.insert(conditions, '[[opponentname::' .. opponent .. ']]')
	else
		local rawOpponentTemplate = Team.queryRaw(opponent) or {}
		local opponentTemplate = rawOpponentTemplate.historicaltemplate or rawOpponentTemplate.templatename
		if not opponentTemplate then
			error('Missing team template for team: ' .. opponent)
		end

		local teamTemplates = Team.queryHistorical(opponentTemplate)
		teamTemplates = teamTemplates and Array.extractValues(teamTemplates) or {opponentTemplate}
		local opponentConditions = Array.map(teamTemplates, function(teamTemplate)
			return '[[opponenttemplate::' .. teamTemplate .. ']]'
		end)

		table.insert(conditions, '(' .. table.concat(opponentConditions, ' OR ') .. ')')
	end

	return table.concat(conditions, ' AND ')
end

---Fetches the placement count values for a given tier
---@param tier string
---@param baseConditions string
---@param placementData InfoboxPlacementStatsData
function PlacementStats._fetchForTier(tier, baseConditions, placementData)
	placementData.tiers[tier] = {top3 = 0, all = 0, placement = {}}

	local queryData = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = 5000,
		conditions = baseConditions .. ' AND [[liquipediatier::' .. tier .. ']]',
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
---@return Html
function PlacementStats._buildTable(placementData, tiers)
	local display = mw.html.create('table')
		:addClass('wikitable sortable wikitable-striped wikitable-bordered')
		:css('text-align', 'center')
		:node(PlacementStats._header())

	for _, tier in ipairs(tiers) do
		display:node(PlacementStats._buildRow(placementData.tiers[tier], tier))
	end

	display:node(PlacementStats._buildBottom(placementData))

	local infoboxHeader = mw.html.create('div')
		:tag('div')
			:addClass('infobox-header wiki-backgroundcolor-light')
			:wikitext('Placement Summary')
			:done()

	return mw.html.create('div')
		:addClass('fo-nttax-infobox-wrapper')
		:tag('div')
			:addClass('fo-nttax-infobox wiki-bordercolor-light')
			:node(infoboxHeader)
			:node(display)
			:done()
end

---Builds the header
---@return Html
function PlacementStats._header()
	return mw.html.create('tr')
		:tag('th'):wikitext('Tier'):css('text-align', 'left'):css('width', '100%'):done()
		:tag('th'):node(Medals.display{medal = 1}):done()
		:tag('th'):node(Medals.display{medal = 2}):done()
		:tag('th'):node(Medals.display{medal = 3}):done()
		:tag('th'):wikitext(Abbreviation.make('Top3', 'Total of top 3')):done()
		:tag('th'):wikitext('All'):done()
end

---Builds a row
---@param placementData {top3: integer, all: integer, placement: {[1]: integer, [2]: integer, [3]: integer}}
---@param tier string
---@return Html?
function PlacementStats._buildRow(placementData, tier)
	if placementData.all == 0 then
		return
	end

	local row = mw.html.create('tr')
		:tag('td'):css('text-align', 'left'):wikitext(Tier.display(tier, nil, {link = true})):done()

	for place = 1, 3 do
		row:tag('td'):wikitext(placementData.placement[place])
	end

	return row
		:tag('td'):wikitext(placementData.top3):css('font-weight', 'bold'):done()
		:tag('td'):wikitext(placementData.all):done()
end

---Builds the bottom row
---@param placementData InfoboxPlacementStatsData
---@return Html
function PlacementStats._buildBottom(placementData)
	local row = mw.html.create('tr')
		:tag('th'):css('text-align', 'left'):wikitext('Total'):done()

	for place = 1, 3 do
		row:tag('th'):wikitext(placementData.totals.placement[place])
	end

	return row
		:tag('th'):wikitext(placementData.totals.top3):done()
		:tag('th'):wikitext(placementData.totals.all):done()
end

return Class.export(PlacementStats, {frameOnly = true})
