---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Grid/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class GridContainer: Widget
---@operator call(table): GridContainer
---@field props table<string, any>
local GridContainer = Class.new(Widget)

---@return Widget
function GridContainer:render()
	return HtmlWidgets.Div{
		classes = { 'lp-container-fluid' },
		children = {
			HtmlWidgets.Div{
				classes = { Logic.readBool(self.props.center) and 'lp-row-center' or 'lp-row' },
				css = { ['row-gap'] = self.props.rowGap or '0px' },
				children = self.props.gridCells
			}
		}
	}
end

return GridContainer
