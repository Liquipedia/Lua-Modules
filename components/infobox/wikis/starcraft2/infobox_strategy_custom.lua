---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Strategy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Strategy = require('Module:Infobox/Strategy')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local RaceIcon = require('Module:RaceIcon')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Header = require('Module:Infobox/Widget/Header')
local CleanRace = mw.loadData('Module:CleanRace2')

local CustomStrategy = Class.new()

local _strategy
local _args

local _RACE_MATCHUPS = {
	'ZvZ', 'ZvP', 'ZvT',
	'TvZ', 'TvP', 'TvT',
	'PvZ', 'PvP', 'PvT',
}

local CustomInjector = Class.new(Injector)

function CustomStrategy.run(frame)
	local customStrategy = Strategy(frame)
	_strategy = customStrategy
	_args = customStrategy.args
	customStrategy.createWidgetInjector = CustomStrategy.createWidgetInjector
	return customStrategy:createInfobox(frame)
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

	if Namespace.isMain() then
		local categories = CustomStrategy:_getCategories(_args.race, _args.matchups)
		_strategy.infobox:categories(unpack(categories))
	end

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

return CustomStrategy
