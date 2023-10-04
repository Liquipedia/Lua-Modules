---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Map = Lua.import('Module:Infobox/Map', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomMap = Class.new()

local CustomInjector = Class.new(Injector)

local TYPES = {
	land = 'Land',
	hybrid = 'Hybrid',
	mixed = 'Hybrid',
	water = 'Water',
}

local _args

function CustomMap.run(frame)
	local customMap = Map(frame)
	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	customMap.getWikiCategories = CustomMap.getWikiCategories
	_args = customMap.args
	_args.releasedate = _args.date
	
	return customMap:createInfobox()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Map Type',
		content = {CustomMap:getType(_args.type)}
	})
	table.insert(widgets, Cell{
		name = 'Starting [[Town Center|TC]](s)',
		content = {_args.tc}
	})
	table.insert(widgets, Cell{
		name = 'Walls',
		content = {_args.walls}
	})
	table.insert(widgets, Cell{
		name = 'Nomad',
		content = {_args.nomad}
	})
	table.insert(widgets, Cell{
		name = 'Player Capacity',
		content = {_args.players}
	})
	table.insert(widgets, Cell{
		name = 'Game',
		content = {Page.makeInternalLink(Game.link{game = _args.game})}
	})
	table.insert(widgets, Cell{
		name = 'First Appearance',
		content = {Page.makeInternalLink({onlyIfExists = true}, _args.appearance) or _args.appearance}
	})
	table.insert(widgets, Cell{
		name = 'Competition Span',
		content = {_args.span}
	})
	return widgets
end

function CustomMap:getType(input)
	return TYPES[(input or ''):lower()] or 'Unknown Type'
end

function CustomMap:createWidgetInjector()
	return CustomInjector()
end

function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata = {
		creator = mw.ext.TeamLiquidIntegration.resolve_redirect(args.creator),
		spawns = args.players,
		maptype = CustomMap:getType(args.type),
		icon = args.icon,
		game = Game.name{game = args.game}
	}
	return lpdbData
end

function CustomMap:getWikiCategories(args)
	return {
		'Maps',
		Game.name{game = args.game} .. ' Maps',
		CustomMap:getType(args.type) .. ' Maps',
		CustomMap:getType(args.type) .. ' Maps (' .. Game.abbreviation{game = args.game} .. ')'
	}
end

return CustomMap
