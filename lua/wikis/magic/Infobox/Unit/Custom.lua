---
-- @Liquipedia
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Link = Lua.import('Module:Widget/Basic/Link')
local Image = Lua.import('Module:Widget/Image/Icon/Image')


---@class MagicUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
---@class MagicUnitInfoboxWidgetInjector: WidgetInjector
---@field caller MagicUnitInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit.args.informationType = 'Card'
	unit:setWidgetInjector(CustomInjector(unit))

	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		return {
			Cell{name = 'Expansion', children = {args.expansion}, options = {makeLink = true}},
			Cell{name = 'Artist', children = {args.artist}, options = {makeLink = true}},
		}
	elseif id == 'type' then
		return {
			Cell{name = 'Type', children = {args.type}, options = {makeLink = true}},
			Cell{name = 'Subtype', children = {args.subtype}, options = {makeLink = true}},
			Cell{
				name = 'Color',
				options = {separator = ' '},
				children = args.color and {
					Image{size = '25px', link = args.color, imageLight = 'Magic Color ' .. args.color .. '.png'},
					Link{link = args.color},
				} or nil
			},
			Cell{name = 'Rarity', children = {args.rarity}, options = {makeLink = true}},
		}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	local postfix = ' Cards'
	return Array.append({'Cards'},
		args.expansion and (args.expansion .. postfix) or nil,
		args.type and (args.type .. postfix) or nil,
		args.color and (args.color .. postfix) or nil,
		args.type and args.color and (args.color .. ' ' .. args.type .. postfix) or nil,
		args.artist and ('Cards illustrated by ' .. args.artist) or nil
	)
end

return CustomUnit
