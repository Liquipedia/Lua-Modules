---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Inline
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local BasePlayerDisplay = Lua.import('Module:Widget/PlayerDisplay/Base')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Span = HtmlWidgets.Span
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class InlinePlayerWidget: BasePlayerDisplayWidget
---@operator call(BasePlayerDisplayProps): InlinePlayerWidget
local InlinePlayerWidget = Class.new(BasePlayerDisplay)

---@return Widget
function InlinePlayerWidget:render()
	local children = WidgetUtil.collect(
		self:getFlag(),
		self:getFaction(),
		self:getName()
	)
	return Span{
		classes = {
			'inline-player',
			self.props.flip and 'flipped' or nil,
		},
		css = {['white-space'] = 'pre'},
		children = Array.interleave(
			self.props.flip and Array.reverse(children) or children,
			'&nbsp;'
		)
	}
end

return InlinePlayerWidget
