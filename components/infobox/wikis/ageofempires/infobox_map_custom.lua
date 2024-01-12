---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class AgeofEmpiresMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
local CustomInjector = Class.new(Injector)

local TYPES = {
	land = 'Land',
	hybrid = 'Hybrid',
	mixed = 'Hybrid',
	water = 'Water',
}

function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Map Type', content = {self.caller:getType(args.type)}},
			Cell{name = 'Starting [[Town Center|TC]](s)', content = {args.tc}},
			Cell{name = 'Walls', content = {args.walls}},
			Cell{name = 'Nomad', content = {args.nomad}},
			Cell{name = 'Player Capacity', content = {args.players}},
			Cell{name = 'Game', content = {Page.makeInternalLink(Game.link{game = args.game})}},
			Cell{
				name = 'First Appearance',
				content = {Page.makeInternalLink({onlyIfExists = true}, args.appearance) or args.appearance}
			},
			Cell{name = 'Competition Span', content = {args.span}}
		)
	end
	return widgets
end

function CustomMap:getType(input)
	return TYPES[(input or ''):lower()] or 'Unknown Type'
end

function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata = {
		creator = String.isNotEmpty(args.creator) and mw.ext.TeamLiquidIntegration.resolve_redirect(args.creator) or nil,
		spawns = args.players,
		maptype = self:getType(args.type),
		icon = args.icon,
		game = Game.name{game = args.game}
	}
	return lpdbData
end

function CustomMap:getWikiCategories(args)
	return {
		Game.name{game = args.game} .. ' Maps',
		self:getType(args.type) .. ' Maps',
		self:getType(args.type) .. ' Maps (' .. Game.abbreviation{game = args.game} .. ')'
	}
end

return CustomMap
