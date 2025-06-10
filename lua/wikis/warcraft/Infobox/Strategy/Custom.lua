---
-- @Liquipedia
-- page=Module:Infobox/Strategy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Strategy = Lua.import('Module:Infobox/Strategy')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header

local STRATEGY_INFORMATION_TYPE = 'Strategy'

---@class WarcraftStrategyInfobox: StrategyInfobox
local CustomStrategy = Class.new(Strategy)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomStrategy.run(frame)
	local strategy = CustomStrategy(frame)
	strategy:setWidgetInjector(CustomInjector(strategy))

	if Namespace.isMain() then
		local categories = strategy:_getCategories(strategy.args.race, strategy.args.matchups)
		strategy:categories(unpack(categories))
	end

	return strategy:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'header' then
		return {
			Header{
				name = self.caller:_getNameDisplay(),
				image = args.image
			},
		}
	elseif id == 'custom' then
		return {
			Cell{name = 'Matchups', content = {args.matchups or 'All'}},
			Cell{name = 'Type', content = {args.type or 'Opening'}},
			Cell{name = 'Popularized by', content = {args.popularized}, options = {makeLink = true}},
			Cell{name = 'Converted Form', content = {args.convert}},
			Cell{name = 'TL-Article', content = {self.caller:_getTLarticle(args.tlarticle)}},
		}
	end
	return widgets
end

---@return string
function CustomStrategy:_getNameDisplay()
	local race = Faction.Icon{size = 'large', faction = self.args.race} or ''
	return race .. (self.args.name or mw.title.getCurrentTitle().text)
end

---@param tlarticle string?
---@return string?
function CustomStrategy:_getTLarticle(tlarticle)
	if not String.isEmpty(tlarticle) then
		---@cast tlarticle -nil
		return '[[File:TL Strategy presents.png|left|95px]] ' ..
			'This article is a spotlighted, peer-reviewed guide by TL Strategy. ['
			.. tlarticle .. ' Link]'
	end
end

---@param race string?
---@param matchups string?
---@return string[]
function CustomStrategy:_getCategories(race, matchups)
	race = Faction.toName(Faction.read(race))
	if String.isEmpty(matchups) or not race then
		return {'InfoboxIncomplete'}
	end

	local categories = {}

	local informationType = self.args.informationType
	if informationType == STRATEGY_INFORMATION_TYPE then
		informationType = 'Build Order'
	end

	table.insert(categories, race .. ' ' .. informationType .. 's')

	matchups = (matchups or ''):lower()
	if informationType == 'Build Order' then
		for _, raceMatchupItem in pairs(CustomStrategy._raceMatchups()) do
			if String.contains(matchups, raceMatchupItem) then
				table.insert(categories, raceMatchupItem .. '_Builds')
			end
		end
	end

	return categories
end

---@return string[]
function CustomStrategy._raceMatchups()
	local raceMatchups = {}
	for _, faction1 in pairs(Faction.coreFactions) do
		for _, faction2 in pairs(Faction.coreFactions) do
			table.insert(raceMatchups, faction1 .. 'v' .. faction2)
		end
	end

	return raceMatchups
end

return CustomStrategy
