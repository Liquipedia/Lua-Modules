---
-- @Liquipedia
-- page=Module:Infobox/Item/Suit
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
			Title { children = 'Suit Information' },
		}
	elseif id == 'custom' then
		return {
			Cell { name = 'Name', children = { args.name } },
			Cell { name = 'Tier', children = { args.tier } },
			Cell { name = 'Description', children = { args.description } }
		}
	end

	return widgets
end

return CustomItem
