---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Inline/SmashLike
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Characters = Lua.import('Module:Characters')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local InlineName = Lua.import('Module:Widget/PlayerDisplay/Inline/Name')
local InlineWrapper = Lua.import('Module:Widget/PlayerDisplay/Inline/Wrapper')
local PlayerDisplayComponents = Lua.import('Module:Widget/PlayerDisplay/Components')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class SmashLikeInlinePlayerDisplayProps: InlinePlayerDisplayProps
---@field player FightersStandardPlayer|SmashStandardPlayer

---@param props SmashLikeInlinePlayerDisplayProps
---@return VNode
local function SmashLikeInlinePlayer(props)
	local player = props.player
	return InlineWrapper{
		flip = props.flip,
		children = WidgetUtil.collect(
			PlayerDisplayComponents.flag{
				player = player,
				showFlag = props.showFlag,
				useDefault = Logic.nilOr(Logic.readBoolOrNil(props.showTbd), not Opponent.playerIsTbd(player))
			},
			Html.Fragment{children = Array.map(
				player.chars,
				function (character)
					return Characters.GetIconAndName{character, game = player.game}
				end
			)},
			InlineName(props)
		)
	}
end

return Component.component(SmashLikeInlinePlayer, PlayerDisplayComponents.defaultProps)
