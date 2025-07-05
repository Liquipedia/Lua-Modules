---
-- @Liquipedia
-- page=Module:Infobox/Expansion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Expansion = Lua.import('Module:Infobox/Expansion')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class AoeExpansionInfobox: ExpansionInfobox
local CustomExpansion = Class.new(Expansion)

---@class AoeExpansionInfoboxWidgetInjector: WidgetInjector
---@field caller AoeExpansionInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomExpansion.run(frame)
	local expansion = CustomExpansion(frame)
	expansion:setWidgetInjector(CustomInjector(expansion))
	return expansion:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args  = self.caller.args
	if id == 'custom' then
		return {
			Cell{name = 'Compilatons', children = {args.compilatons}},
		}
	end

	return widgets
end

---@return string
function CustomExpansion:chronologyTitle()
	return 'Connected Games'
end


return CustomExpansion
