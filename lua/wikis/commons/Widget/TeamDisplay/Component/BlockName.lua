---
-- @Liquipedia
-- page=Module:Widget/TeamDisplay/Component/BlockName
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DisplayUtil = Lua.import('Module:DisplayUtil')
local String = Lua.import('Module:StringUtils')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class BlockTeamNameDisplayParameters
---@field additionalClasses string[]?
---@field displayName string
---@field overflowStyle OverflowModes?
---@field noLink boolean?
---@field page string?
---@field dq boolean?

local BlockTeamNameDisplay = {}
BlockTeamNameDisplay.defaultProps = {overflowStyle = 'ellipsis'}

---@param props BlockTeamNameDisplayParameters
---@return VNode
function BlockTeamNameDisplay.render(props)
	local displayName = props.displayName
	local page = props.page
	local container = props.dq and Html.S or Html.Span
	return container{
		classes = Array.extend('name', props.additionalClasses),
		css = DisplayUtil.getOverflowStyles(props.overflowStyle),
		children = {
			(props.noLink and String.isNotEmpty(page)) and displayName or Link{
				children = displayName,
				link = props.page
			}
		}
	}
end

return Component.component(BlockTeamNameDisplay.render, BlockTeamNameDisplay.defaultProps)
