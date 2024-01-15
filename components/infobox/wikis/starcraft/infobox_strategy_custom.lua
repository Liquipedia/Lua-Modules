---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Infobox/Strategy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Strategy = Lua.import('Module:Infobox/Strategy')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header

local DEFAULT_COUNTER_GAME = 'Starcraft: Broodwar'
local COUNTER_INFORMATION_TYPE = 'Counter'
local STRATEGY_INFORMATION_TYPE = 'Strategy'

local CustomStrategy = Class.new()

local _args

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomStrategy.run(frame)
	local customStrategy = Strategy(frame)
	_args = customStrategy.args

	customStrategy.createWidgetInjector = CustomStrategy.createWidgetInjector

	if Namespace.isMain() then
		local categories = CustomStrategy:_getCategories(_args.race, _args.matchups)
		customStrategy.infobox:categories(unpack(categories))
	end

	return customStrategy:createInfobox()
end

---@return WidgetInjector
function CustomStrategy:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return {
		Cell{name = 'Matchups', content = {_args.matchups or 'All'}},
		Cell{name = 'Type', content = {_args.type or 'Opening'}},
		Cell{name = 'Popularized by', content = {_args.popularized}},
		Cell{name = 'Converted Form', content = {_args.convert}},
		Cell{name = 'TL-Article', content = {CustomStrategy:_getTLarticle(_args.tlarticle)}},
		Cell{name = 'Game', content = {_args.game or
			(_args.informationType == COUNTER_INFORMATION_TYPE and DEFAULT_COUNTER_GAME or nil)}},
	}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'header' then
		return {
			Header{
				name = CustomStrategy:_getNameDisplay(),
				image = _args.image
			},
		}
	end
	return widgets
end

---@return string
function CustomStrategy:_getNameDisplay()
	local race = Faction.Icon{size = 'large', faction = _args.race} or ''
	return race .. (_args.name or mw.title.getCurrentTitle().text)
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
	---@cast matchups -nil

	local categories = {}

	local informationType = _args.informationType
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
