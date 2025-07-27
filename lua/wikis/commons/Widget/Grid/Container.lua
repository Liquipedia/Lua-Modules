---
-- @Liquipedia
-- page=Module:Widget/Grid/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class GridContainerParameters
---@field center boolean?
---@field rowGap string?
---@field gridCells (Widget|string|Html|nil)|(Widget|string|Html|nil)[]

---@class GridContainer: Widget
---@operator call(GridContainerParameters): GridContainer
---@field props GridContainerParameters
local GridContainer = Class.new(Widget)

GridContainer.defaultProps = {
	center = false,
	rowGap = '0px'
}

---@return Widget
function GridContainer:render()
	return HtmlWidgets.Div{
		classes = { 'lp-container-fluid' },
		children = {
			HtmlWidgets.Div{
				classes = { Logic.readBool(self.props.center) and 'lp-row-center' or 'lp-row' },
				css = { ['row-gap'] = self.props.rowGap },
				children = self.props.gridCells
			}
		}
	}
end

return GridContainer
