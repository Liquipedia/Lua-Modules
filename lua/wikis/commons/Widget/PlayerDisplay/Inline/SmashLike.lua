---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Inline/SmashLike
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Characters = Lua.import('Module:Characters')
local Class = Lua.import('Module:Class')

local InlinePlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Inline')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Span = HtmlWidgets.Span
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class SmashLikeInlinePlayerProps: BasePlayerDisplayProps
---@field player FightersStandardPlayer|SmashStandardPlayer

---@class SmashLikeInlinePlayerWidget: InlinePlayerWidget
---@operator call(SmashLikeInlinePlayerProps): InlinePlayerWidget
---@field protected player FightersStandardPlayer|SmashStandardPlayer
local CustomInlinePlayerWidget = Class.new(InlinePlayerWidget)

---@return Widget
function CustomInlinePlayerWidget:render()
	local children = WidgetUtil.collect(
		self:getFlag(),
		HtmlWidgets.Fragment{children = Array.map(
			self.player.chars,
			function (character)
				return Characters.GetIconAndName{character, game = self.player.game}
			end
		)},
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

return CustomInlinePlayerWidget
