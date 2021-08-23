---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Strategy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Strategy = require('Module:Infobox/Strategy')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local RaceIcon = require('Module:RaceIcon')
local StarCraft2Strategy = {}

function StarCraft2Strategy.run(frame)
	local strategy = Strategy(frame)
	strategy.getNameDisplay = StarCraft2Strategy.getNameDisplay
	strategy.addCustomCells = StarCraft2Strategy.addCustomCells
	return strategy:createInfobox(frame)
end

function StarCraft2Strategy:addCustomCells(infobox, args)
	infobox:cell('Matchups', args.matchups)
	infobox:cell('Type', args.type or 'Opening')
	infobox:cell('Popularized by', args.popularized)
	infobox:cell('Converted Form', args.convert)
	infobox:cell('TL-Article', StarCraft2Strategy:_getTLarticle(args.tlarticle))

	if Namespace.isMain() then
		local categories = StarCraft2Strategy:_getCategories(args.race, args.matchups)
		infobox:categories(unpack(categories))
	end

	return infobox
end

function StarCraft2Strategy:getNameDisplay(args)
	local race = RaceIcon._getBigIcon({'alt_' .. (args.race or '')}) or ''
	return race .. (args.name or mw.title.getCurrentTitle().text)
end

function StarCraft2Strategy:_getTLarticle(tlarticle)
	if not String.isEmpty(tlarticle) then
		return '[[File:TL Strategy presents.png|left|95px]] ' ..
			'This article is a spotlighted, peer-reviewed guide by TL Strategy. ['
			.. tlarticle .. ' Link]'
	end
end

function StarCraft2Strategy:_getCategories(race, matchups)
	local categories = {}
	race = string.lower(race or '')
	local raceCategories = {
		z = 'Zerg_Build_Orders',
		zerg = 'Zerg_Build_Orders',
		p = 'Protoss_Build_Orders',
		protoss = 'Protoss_Build_Orders',
		t = 'Terran_Build_Orders',
		terran = 'Terran_Build_Orders',
	}
	table.insert(categories, raceCategories[race] or 'Build Orders')
	local raceMatchups = {
		'ZvZ', 'ZvP', 'ZvT',
		'TvZ', 'TvP', 'TvT',
		'PvZ', 'PvP', 'PvT',
	}
	for _, raceMatchupItem in ipairs(raceMatchups) do
		if String.contains(matchups, raceMatchupItem) then
			table.insert(categories, raceMatchupItem .. '_Builds')
		end
	end

	return categories
end

return StarCraft2Strategy
