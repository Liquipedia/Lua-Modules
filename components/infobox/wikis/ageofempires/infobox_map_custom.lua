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

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Widget/All')
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

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Map Type', content = {self.caller:_getType(args.type)}},
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

---@param input string?
---@return string
function CustomMap:_getType(input)
	return TYPES[(input or ''):lower()] or 'Unknown Type'
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata = {
		creator = String.isNotEmpty(args.creator) and mw.ext.TeamLiquidIntegration.resolve_redirect(args.creator) or nil,
		spawns = args.players,
		maptype = self:_getType(args.type),
		icon = args.icon,
		game = Game.name{game = args.game}
	}
	return lpdbData
end

---@param args table
---@return string[]
function CustomMap:getWikiCategories(args)
	return {
		Game.name{game = args.game} .. ' Maps',
		self:_getType(args.type) .. ' Maps',
		self:_getType(args.type) .. ' Maps (' .. Game.abbreviation{game = args.game} .. ')'
	}
end

return CustomMap
