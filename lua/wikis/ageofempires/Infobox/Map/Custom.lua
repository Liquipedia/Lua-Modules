---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class AgeofEmpiresMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class AgeofEmpiresMapInfoboxWidgetInjector: WidgetInjector
---@field caller AgeofEmpiresMapInfobox
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
	map.args.useDefaultGame = false

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
			}
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
	lpdbData.extradata = Table.merge(lpdbData.extradata, {
		spawns = args.players,
		maptype = self:_getType(args.type),
		icon = args.icon,
	})
	return lpdbData
end

---@param args table
---@return string[]
function CustomMap:getWikiCategories(args)
	return {
		self:getGame(args) .. ' Maps',
		self:_getType(args.type) .. ' Maps',
		self:_getType(args.type) .. ' Maps (' .. Game.abbreviation{game = args.game} .. ')'
	}
end

return CustomMap
