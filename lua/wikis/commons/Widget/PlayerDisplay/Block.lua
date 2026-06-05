---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Block
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local Html = Lua.import('Module:Widget/Html')
local Component = Lua.import('Module:Widget/Component')
local BlockName = Lua.import('Module:Widget/PlayerDisplay/Block/Name')
local BlockWrapper = Lua.import('Module:Widget/PlayerDisplay/Block/Wrapper')
local PlayerDisplayComponents = Lua.import('Module:Widget/PlayerDisplay/Components')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class BlockPlayerDisplayProps: InlinePlayerDisplayProps
---@field playerClass string|string[]?
---@field overflow OverflowModes?
---@field showPlayerTeam boolean?
---@field note Renderable|Renderable[]?

---@param props BlockPlayerDisplayProps
---@return VNode
local function BlockPlayer(props)
	local player = props.player
	local factionDisplay = PlayerDisplayComponents.faction(props)
	local playerClasses = type(props.playerClass) == 'string' and
		{props.playerClass} or props.playerClass --[[ @as string[]? ]]
	local useDefault = Logic.nilOr(Logic.readBoolOrNil(props.showTbd), not Opponent.playerIsTbd(player))
	return BlockWrapper{
		classes = playerClasses,
		children = WidgetUtil.collect(
			PlayerDisplayComponents.flag{
				player = player,
				showFlag = props.showFlag,
				useDefault = useDefault,
			},
			factionDisplay and Html.Span{
				classes = {'race'},
				children = factionDisplay
			} or nil,
			BlockName{
				player = player,
				showLink = props.showLink,
				dq = props.dq,
				overflow = props.overflow,
				useDefault = useDefault,
			},
			Logic.isNotEmpty(props.note) and Html.Sup{children = props.note} or nil,
			PlayerDisplayComponents.getTeam(player, props.showPlayerTeam)
		)
	}
end

return Component.component(BlockPlayer)
