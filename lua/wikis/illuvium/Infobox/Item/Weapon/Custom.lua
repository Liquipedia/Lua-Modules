---
-- @Liquipedia
-- page=Module:Infobox/Item/Weapon/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Injector = Lua.import('Module:Widget/Injector')
local Item = Lua.import('Module:Infobox/Item')

local Widgets = Lua.import('Module:Widget/All')
local Title = Widgets.Title
local Cell = Widgets.Cell

---@class IlluvItemWeaponInfobox: ItemInfobox
local CustomItem = Class.new(Item)
local CustomInjector = Class.new(Injector)

local CLASS_TYPE = {
	rogue = 'Rogue',
	fighter = 'Fighter',
	psion = 'Psion',
	empath = 'Empath',
	bulwark = 'Bulwark',
}

---@param frame Frame
---@return Widget
function CustomItem.run(frame)
	local item = CustomItem(frame)
	item:setWidgetInjector(CustomInjector(item))

	return item:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'info' then
		return {
			Title{children = 'Weapon Information'},
			Cell{name = 'Weapon type', children = {args.type}},
			Cell{name = 'Class', children = {CLASS_TYPE[(args.class or ''):lower()]}},
		}
	elseif id == 'custom' then
		return {
			Cell{name = 'Tier', children = {args.tier}}
		}
	end

	return widgets
end

return CustomItem
