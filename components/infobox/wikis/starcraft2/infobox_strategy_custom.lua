---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Strategy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local CleanRace = mw.loadData('Module:CleanRace2')
local Lua = require('Module:Lua')
local RaceIcon = require('Module:RaceIcon')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Strategy = Lua.import('Module:Infobox/Strategy', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header

local CustomStrategy = Class.new()

local _args

local _RACE_MATCHUPS = {
	'ZvZ', 'ZvP', 'ZvT',
	'TvZ', 'TvP', 'TvT',
	'PvZ', 'PvP', 'PvT',
}

local CustomInjector = Class.new(Injector)

function CustomStrategy.run(frame)
	local customStrategy = Strategy(frame)
	_args = customStrategy.args
	customStrategy.createWidgetInjector = CustomStrategy.createWidgetInjector
	customStrategy.getWikiCategories = CustomStrategy.getWikiCategories
	return customStrategy:createInfobox()
end

function CustomStrategy:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Matchups',
		content = {_args.matchups or 'All'}
	})
	table.insert(widgets, Cell{
		name = 'Type',
		content = {_args.type or 'Opening'}
	})
	table.insert(widgets, Cell{
		name = 'Popularized by',
		content = {_args.popularized},
		options = {makeLink = true}
	})
	table.insert(widgets, Cell{
		name = 'Converted Form',
		content = {_args.convert}
	})
	table.insert(widgets, Cell{
		name = 'TL-Article',
		content = {CustomStrategy:_getTLarticle(_args.tlarticle)}
	})

	return widgets
end

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

function CustomStrategy:_getNameDisplay()
	local race = RaceIcon._getBigIcon({'alt_' .. (_args.race or '')}) or ''
	return race .. (_args.name or mw.title.getCurrentTitle().text)
end

function CustomStrategy:_getTLarticle(tlarticle)
	if not String.isEmpty(tlarticle) then
		return '[[File:TL Strategy presents.png|left|95px]] ' ..
			'This article is a spotlighted, peer-reviewed guide by TL Strategy. ['
			.. tlarticle .. ' Link]'
	end
end

function CustomStrategy:_getCategories(race, matchups)
	if String.isEmpty(matchups) then
		return {}
	end

	local categories = {}
	race = string.lower(race or '')
	race = CleanRace[race] or ''

	local informationType = _args.informationType
	if informationType == 'Strategy' then
		informationType = 'Build Order'
	end

	table.insert(categories, race .. ' ' .. informationType .. 's')

	if informationType == 'Build Order' then
		for _, raceMatchupItem in ipairs(_RACE_MATCHUPS) do
			if String.contains(matchups, raceMatchupItem) then
				table.insert(categories, raceMatchupItem .. '_Builds')
			end
		end
	end

	return categories
end

function CustomStrategy:getWikiCategories(args)
	return CustomStrategy:_getCategories(args.race, args.matchups)
end

return CustomStrategy
