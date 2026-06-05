---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Block/SmashLike
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Characters = Lua.import('Module:Characters')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local Component = Lua.import('Module:Widget/Component')
local BlockName = Lua.import('Module:Widget/PlayerDisplay/Block/Name')
local BlockWrapper = Lua.import('Module:Widget/PlayerDisplay/Block/Wrapper')
local Html = Lua.import('Module:Widget/Html')
local PlayerDisplayComponents = Lua.import('Module:Widget/PlayerDisplay/Components')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class SmashLikeBlockPlayerDisplayProps: BlockPlayerDisplayProps
---@field player FightersStandardPlayer|SmashStandardPlayer
---@field oneLine boolean?

---@param player FightersStandardPlayer|SmashStandardPlayer
---@return Renderable[]?
local function getCharacters(player)
	if Logic.isEmpty(player.chars) then
		return
	end
	return Array.interleave(
		Array.map(player.chars, function (character)
			return Html.Span{
				classes = {'race'},
				children = Characters.GetIconAndName{character, game = player.game}
			}
		end),
		' '
	)
end

---@param props SmashLikeBlockPlayerDisplayProps
---@return Renderable|Renderable[]
local function SmashLikeBlockPlayer(props)
	local player = props.player
	local charactersDisplay = getCharacters(player)
	local playerClasses = type(props.playerClass) == 'string' and
		{props.playerClass} or props.playerClass --[[ @as string[]? ]]
	local useDefault = Logic.nilOr(Logic.readBoolOrNil(props.showTbd), not Opponent.playerIsTbd(player))
	local showPlayerTeam = props.showPlayerTeam
	local block = BlockWrapper{
		classes = playerClasses,
		flip = props.flip,
		showPlayerTeam = showPlayerTeam,
		children = WidgetUtil.collect(
			PlayerDisplayComponents.flag{
				player = player,
				showFlag = props.showFlag,
				useDefault = useDefault,
			},
			props.oneLine and charactersDisplay or nil,
			BlockName{
				player = player,
				showLink = props.showLink,
				dq = props.dq,
				overflow = props.overflow,
				useDefault = useDefault,
			},
			Logic.isNotEmpty(props.note) and Html.Sup{children = props.note} or nil,
			PlayerDisplayComponents.team(player, showPlayerTeam)
		)
	}
	if props.oneLine then
		return block
	end
	return WidgetUtil.collect(block, charactersDisplay)
end

return Component.component(SmashLikeBlockPlayer, PlayerDisplayComponents.defaultProps)
