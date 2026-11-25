---
-- @Liquipedia
-- page=Module:Widget/Grid/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class GridContainerParameters
---@field center boolean?
---@field rowGap string?
---@field gridCells Renderable|Renderable[]

local defaultProps = {
	center = false,
	rowGap = '0px'
}

---@param props GridContainerParameters
---@return VNode
local function GridContainer(props)
	return Html.Div{
		classes = { 'lp-container-fluid' },
		children = {
			Html.Div{
				classes = { Logic.readBool(props.center) and 'lp-row-center' or 'lp-row' },
				css = { ['row-gap'] = props.rowGap },
				children = props.gridCells
			}
		}
	}
end

return Component.component(GridContainer, defaultProps)
