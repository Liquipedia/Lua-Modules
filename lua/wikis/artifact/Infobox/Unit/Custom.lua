---
-- @Liquipedia
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class ArtifactUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
---@class ArtifactUnitInfoboxWidgetInjector: WidgetInjector
---@field caller ArtifactUnitInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))

	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		return {
			Cell{name = 'label', children = {}},
		}
	end

	return widgets
end

return CustomUnit
