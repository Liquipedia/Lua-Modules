---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/Old
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class WidgetTableInput
---@field children WidgetTableRow[]?
---@field classes string[]?
---@field css {[string]: string|number|nil}?
---@field columns integer?

---@class WidgetTableOld:Widget
---@operator call(WidgetTableInput):WidgetTableOld
---@field classes string[]
---@field css {[string]: string|number|nil}
---@field columns integer?
local TableOld = Class.new(
	Widget,
	function(self, input)
		self.classes = input.classes or {}
		self.css = input.css or {}
		self.columns = input.columns
	end
)

---@return Widget
function TableOld:render()
	local styles = Table.copy(self.css)
	styles['grid-template-columns'] = 'repeat(' .. (self.columns or self:_getMaxCells()) .. ', auto)'
	return HtmlWidgets.Div{
		classes = WidgetUtil.collect('csstable-widget', unpack(self.classes)),
		css = styles,
		children = self.props.children
	}
end

---@return integer?
function TableOld:_getMaxCells()
	local getNumberCells = function(row)
		return row:getCellCount()
	end
	return Array.reduce(Array.map(self.props.children, getNumberCells), math.max)
end

return TableOld
