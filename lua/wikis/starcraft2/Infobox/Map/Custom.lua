---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class Starcraft2MapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class Starcraft2MapInfoboxWidgetInjector: WidgetInjector
---@field caller Starcraft2MapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param widgetId string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(widgetId, widgets)
	local args = self.caller.args

	if widgetId == 'custom' then
		local id = args.id

	return Array.append(
		widgets,
		Cell{name = 'Tileset', content = {args.tileset or self.caller:_tlpdMap(id, 'tileset')}},
		Cell{name = 'Size', content = {self.caller:_getSize(id)}},
		Cell{name = 'Spawn Positions', content = {self.caller:_getSpawn(id)}},
		Cell{name = 'Versions', content = {args.versions}},
		Cell{name = 'Competition Span', content = {args.span}},
		Cell{name = 'Leagues Featured', content = {args.leagues}},
		Cell{name = '[[Rush distance]]', content = {self.caller:_getRushDistance()}},
		Cell{name = '1v1 Ladder', content = {args['1v1history']}},
		Cell{name = '2v2 Ladder', content = {args['2v2history']}},
		Cell{name = '3v3 Ladder', content = {args['3v3history']}},
		Cell{name = '4v4 Ladder', content = {args['4v4history']}}
	)
	end

	return widgets
end

---@param args table
---@return string?
function CustomMap:getNameDisplay(args)
	if String.isEmpty(args.name) then
		return CustomMap:_tlpdMap(args.id, 'name')
	end

	return args.name
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.name = self:getNameDisplay(args)
	lpdbData.extradata.spawns = args.players
	lpdbData.extradata.height = args.height
	lpdbData.extradata.width = args.width
	lpdbData.extradata.rush = Variables.varDefault('rush_distance')
	return lpdbData
end

---@param id string?
---@return string
function CustomMap:_getSize(id)
	local width = self.args.width
		or self:_tlpdMap(id, 'width') or ''
	local height = self.args.height
		or self:_tlpdMap(id, 'height') or ''
	return width .. 'x' .. height
end

---@param id string?
---@return string
function CustomMap:_getSpawn(id)
	local players = self.args.players
		or self:_tlpdMap(id, 'players') or ''
	local positions = self.args.positions
		or self:_tlpdMap(id, 'positions') or ''
	return players .. ' at ' .. positions
end

---@return string?
function CustomMap:_getRushDistance()
	if String.isEmpty(self.args['rush_distance']) then
		return nil
	end
	local rushDistance = self.args['rush_distance']
	rushDistance = string.gsub(rushDistance, 's', '')
	rushDistance = string.gsub(rushDistance, 'seconds', '')
	rushDistance = string.gsub(rushDistance, ' ', '')
	Variables.varDefine('rush_distance', rushDistance)
	return rushDistance .. ' seconds'
end

---@param id string?
---@param query string
---@return string?
function CustomMap:_tlpdMap(id, query)
	if not id then return nil end
	return Template.safeExpand(mw.getCurrentFrame(), 'Tlpd map', {id, query})
end

---@param args table
---@return string[]
function CustomMap:getWikiCategories(args)
	local players = args.players
	if String.isEmpty(players) then
		players = self:_tlpdMap(args.id, 'players')
	end

	if String.isEmpty(players) then
		return {}
	end

	return {'Maps (' .. players .. ' Players)'}
end

return CustomMap
