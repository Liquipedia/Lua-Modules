---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Block/SmashLike
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Characters = Lua.import('Module:Characters')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local BlockPlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Block')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class SmashLikeBlockPlayerProps: BlockPlayerProps
---@field player FightersStandardPlayer|SmashStandardPlayer
---@field oneLine boolean?

---@class SmashLikeBlockPlayerWidget: BlockPlayerWidget
---@operator call(SmashLikeBlockPlayerProps): SmashLikeBlockPlayerWidget
---@field protected player FightersStandardPlayer|SmashStandardPlayer
---@field props SmashLikeBlockPlayerProps
local CustomBlockPlayerWidget = Class.new(BlockPlayerWidget)

---@return Widget|(string|Widget)[]
function CustomBlockPlayerWidget:render()
	local props = self.props
	local charactersDisplay = self:getCharacters()
	local block = Div{
		classes = Array.extend(
			'block-player',
			self.props.flip and 'flipped' or nil,
			self.props.showPlayerTeam and 'has-team' or nil
		),
		css = {['white-space'] = 'pre'},
		children = WidgetUtil.collect(
			self:getFlag(),
			props.oneLine and charactersDisplay or nil,
			self:getName(),
			Logic.isNotEmpty(props.note) and HtmlWidgets.Sup{children = props.note} or nil,
			self:getTeam()
		)
	}
	if props.oneLine then
		return block
	end
	return WidgetUtil.collect(block, charactersDisplay)
end

---@protected
---@return (string|Widget)[]?
function CustomBlockPlayerWidget:getCharacters()
	local player = self.player
	if Logic.isEmpty(player.chars) then
		return
	end
	return Array.interleave(
		Array.map(player.chars, function (character)
			return Span{
				classes = {'race'},
				children = Characters.GetIconAndName{character, game = player.game}
			}
		end),
		' '
	)
end

return CustomBlockPlayerWidget
