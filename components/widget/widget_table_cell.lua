---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Table/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class WidgetCellInput
---@field children (string|number|table|Html)[]?
---@field classes string[]?
---@field css {[string]: string|number}?

---@class WidgetTableCell:Widget
---@operator call(WidgetCellInput): WidgetTableCell
---@field classes string[]
---@field css {[string]: string|number}
---@field rowSpan integer?
---@field colSpan integer?
local TableCell = Class.new(
	Widget,
	function(self, input)
		self.classes = input.classes or {}
		self.css = input.css or {}
	end
)

---@param text string|number|table|nil
---@return self
function TableCell:addContent(text)
	table.insert(self.children, text)
	return self
end

---@param class string|nil
---@return self
function TableCell:addClass(class)
	table.insert(self.classes, class)
	return self
end

---@param key string
---@param value string|number|nil
---@return self
function TableCell:addCss(key, value)
	self.css[key] = value
	return self
end

---@param children string[]
---@return string?
function TableCell:make(children)
	local cell = mw.html.create('div'):addClass('csstable-widget-cell')
	cell:css{
		['grid-row'] = self.rowSpan and 'span ' .. self.rowSpan or nil,
		['grid-column'] = self.colSpan and 'span ' .. self.colSpan or nil,
	}

	for _, class in ipairs(self.classes) do
		cell:addClass(class)
	end

	cell:css(self.css)

	for _, child in ipairs(children) do
		cell:node(child)
	end

	return tostring(cell)
end

return TableCell
