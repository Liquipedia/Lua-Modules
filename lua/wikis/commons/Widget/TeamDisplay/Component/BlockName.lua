---
-- @Liquipedia
-- page=Module:Widget/TeamDisplay/Component/BlockName
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local String = Lua.import('Module:StringUtils')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class BlockTeamNameDisplayParameters
---@field additionalClasses string[]?
---@field displayName string
---@field overflowStyle OverflowModes?
---@field noLink boolean?
---@field page string?
---@field dq boolean?

---@class BlockTeamNameDisplay: Widget
---@operator call(BlockTeamNameDisplayParameters): BlockTeamNameDisplay
---@field props BlockTeamNameDisplayParameters
local BlockTeamNameDisplay = Class.new(Widget)
BlockTeamNameDisplay.defaultProps = {overflowStyle = 'ellipsis'}

---@return Widget
function BlockTeamNameDisplay:render()
	local displayName = self.props.displayName
	local page = self.props.page
	local container = self.props.dq and HtmlWidgets.S or HtmlWidgets.Span
	return container{
		classes = Array.extend('name', self.props.additionalClasses),
		css = BlockTeamNameDisplay._getOverflowStyleCss(self.props.overflowStyle),
		children = {
			(self.props.noLink and String.isNotEmpty(page)) and displayName or Link{
				children = displayName,
				link = self.props.page
			}
		}
	}
end

---@param mode OverflowModes
---@return table<string, string?>
BlockTeamNameDisplay._getOverflowStyleCss = FnUtil.memoize(function(mode)
	return {
		['overflow'] = (mode == 'ellipsis' or mode == 'hidden') and 'hidden' or nil,
		['overflow-wrap'] = mode == 'wrap' and 'break-word' or nil,
		['text-overflow'] = mode == 'ellipsis' and 'ellipsis' or nil,
		['white-space'] = (mode == 'ellipsis' or mode == 'hidden') and 'pre' or 'normal',
	}
end)

return BlockTeamNameDisplay
