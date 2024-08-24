---
-- @Liquipedia
-- wiki=pubg
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class PUBGMapInfobox: MapInfobox
local CustomMap = Class.new(Map)

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

	return Array.append(
		widgets,
		Cell{name = 'Theme', content = {args.theme}},
		Cell{name = 'Size', content = {args.size}},
		Cell{name = 'Competition Span', content = {args.span}},
        Cell{name = 'Versions', content = {args.versions}}
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
	lpdbData.extradata = {
		}
	return lpdbData
end

---@param id string?
---@param query string
---@return string?
function CustomMap:_tlpdMap(id, query)
	if not id then return nil end
	return Template.safeExpand(mw.getCurrentFrame(), 'Tlpd map', {id, query})
end

return CustomMap
