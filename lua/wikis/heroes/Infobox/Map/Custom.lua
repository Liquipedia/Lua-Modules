---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class HeroesMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class HeroesMapInfoboxWidgetInjector: WidgetInjector
---@field caller HeroesMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map.args.informationType = 'Battleground'
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args
	if id == 'custom' then
		return WidgetUtil.collect(
			Cell{name = 'Universe', children = {args.universe and Template.safeExpand(
				mw.getCurrentFrame(), 'Faction icon', {args.universe}) or nil}},
			caller:_objectives(),
			caller:_creatures(),
			Title{children = {'Map Data'}},
			Cell{name = 'Lanes', children = {args.lanes}},
			Cell{name = 'Mercenary camps', children = {args.mercenarycamps}},
			caller:_image2()
		)
	end
	return widgets
end

---@param args table
---@return string[]
function CustomMap:getWikiCategories(args)
	return {
		'Battlegrounds',
		args.universe and (args.universe .. ' Battlegrounds') or nil,
	}
end

---@return Widget[]?
function CustomMap:_objectives()
	local objectives = self:getAllArgsForBase(self.args, 'objective')
	if Logic.isEmpty(objectives) then return end
	return {
		Title{children = {'Main Objectives'}},
		Center{children = Array.interleave(objectives, '&nbsp;')}
	}
end

---@return Widget[]?
function CustomMap:_creatures()
	local creatures = self:getAllArgsForBase(self.args, 'creature')
	if Logic.isEmpty(creatures) then return end
	creatures = Array.map(creatures, function(creature)
		return Template.safeExpand(mw.getCurrentFrame(), 'CreatureIcon', {creature})
	end)
	return {
		Title{children = {'Creatures'}},
		Center{children = Array.interleave(creatures, '&nbsp;')}
	}
end

---@return Widget?
function CustomMap:_image2()
	if not self.args.image2 then return end
	return HtmlWidgets.Div{
		classes = {'infobox-image'},
		children = {Image{
			imageLight = self.args.image2,
			size = '294px',
			alignment = 'center',
		}}
	}
end

return CustomMap
