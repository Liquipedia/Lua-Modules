---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Inline
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local Component = Lua.import('Module:Widget/Component')
local InlineName = Lua.import('Module:Widget/PlayerDisplay/Inline/Name')
local InlineWrapper = Lua.import('Module:Widget/PlayerDisplay/Inline/Wrapper')
local PlayerDisplayComponents = Lua.import('Module:Widget/PlayerDisplay/Components')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class InlinePlayerDisplayProps
---@field flip boolean?
---@field player standardPlayer
---@field showFlag boolean?
---@field showLink boolean?
---@field dq boolean?
---@field showFaction boolean?
---@field game string?
---@field showTbd boolean?

---@param props InlinePlayerDisplayProps
---@return Widget
local function InlinePlayer(props)
	local player = props.player
	return InlineWrapper{
		flip = props.flip,
		children = WidgetUtil.collect(
			PlayerDisplayComponents.flag{
				player = player,
				showFlag = props.showFlag,
				useDefault = Logic.nilOr(Logic.readBoolOrNil(props.showTbd), not Opponent.playerIsTbd(player))
			},
			PlayerDisplayComponents.faction(props),
			InlineName(props)
		)
	}
end

return Component.component(InlinePlayer, PlayerDisplayComponents.defaultProps)
