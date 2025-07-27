---
-- @Liquipedia
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Variables = Lua.import('Module:Variables')
local VersionDisplay = Lua.import('Infobox/Extension/VersionDisplay')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Item = Lua.import('Module:Infobox/Item')

local Widgets = Lua.import('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class FortniteItemInfobox: ItemInfobox
local CustomItem = Class.new(Item)
---@class FortniteItemInfoboxInjector
---@field caller FortniteItemInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomItem.run(frame)
	local item = CustomItem(frame)
	local args = item.args
	if Logic.readBool(args['generate description']) then
		item:_createDescription()
	end

	item:setWidgetInjector(CustomInjector(item))

	return item:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'released' then
		return {
			Cell{name = 'Released', content = {VersionDisplay.run(args.release)}},
			Cell{name = 'Removed', children = {VersionDisplay.run(args.removed)}},
		}
	end

	return widgets
end

---@private
function CustomItem:_createDescription()
	local rarities = self:getAllArgsForBase(self.args, 'rarity')
	local description = '<b>' .. self.name .. '</b> is an item that is available in  '
		.. mw.text.listToText(rarities, ', ', ' and ')
		.. ' ' .. (#rarities > 1 and 'rarities' or 'rarity')

	Variables.varDefine('description', description)
end

---@param args table
---@return string[]
function CustomItem:getWikiCategories(args)
	return Array.map(self:getAllArgsForBase(self.args, 'rarity'), function(rarity)
		return rarity .. ' Items'
	end)
end

return CustomItem
