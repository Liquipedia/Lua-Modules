---
-- @Liquipedia
-- page=Module:Infobox/Item/Augment
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

---@class IlluvItemInfobox: ItemInfobox
local CustomItem = Class.new(Item)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
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
			Title { children = 'Augment Information' },
		}
	elseif id == 'custom' then
		return {
			Cell { name = 'Type', children = { args.type } },
			Cell { name = 'Trigger Type', children = { args.trigger } },
			Title { children = 'Mastery Point Costs' },
			Cell { name = 'Lesser', children = { args.lesser } },
			Cell { name = 'Greater', children = { args.greater } },
			Cell { name = 'Exalted', children = { args.exalted } }
		}
	end

	return widgets
end

return CustomItem
