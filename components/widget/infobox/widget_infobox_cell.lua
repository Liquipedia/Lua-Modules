---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class CellWidgetOptions
---@field columns number?
---@field makeLink boolean?
---@field surpressColon boolean?

---@class CellWidget: Widget
---@operator call(table):CellWidget
local Cell = Class.new(Widget,
	function(self, input)
		self.name = self:assertExistsAndCopy(input.name)
		self.props.children = input.children or input.content or {}
	end
)
Cell.defaultProps = {
	options = {
		columns = 2,
		makeLink = false,
		surpressColon = false,
	}
}

---@return Widget?
function Cell:render()
	if Logic.isEmpty(self.props.children) then
		return
	end

	local options = self.props.options

	local mappedChildren = {}
	for i, child in ipairs(self.props.children) do
		if i > 1 then
			table.insert(mappedChildren, '<br/>')
		end
		if options.makeLink then
			table.insert(mappedChildren, Link{children = {child}, link = child})
		else
			table.insert(mappedChildren, child)
		end
	end

	if Logic.isEmpty(mappedChildren[1]) then
		return
	end

	return HtmlWidgets.Div{
		classes = self.props.classes,
		children = {
			HtmlWidgets.Div{
				classes = {'infobox-cell-' .. options.columns, 'infobox-description'},
				children = {self.props.name, not options.surpressColon and ':' or nil}
			},
			HtmlWidgets.Div{
				css = {width = (100 * (options.columns - 1) / options.columns) .. '%'}, -- 66.66% for col = 3
				children = mappedChildren,
			}
		}
	}
end

return Cell
