---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/ScoreContainer/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Characters = Lua.import('Module:Characters')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')

local BracketScoreContainer = Lua.import('Module:Widget/Match/Bracket/ScoreContainer')
local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {opponent: SmashStandardOpponent}
---@return VNode
local function SmashBracketScoreContainer(props)
	local opponent = props.opponent
	if opponent.placement2 or opponent.type ~= Opponent.solo then
		return BracketScoreContainer(props)
	end

	local player = opponent.players[1]
	local game = player.game

	if Opponent.playerIsTbd(player) or Logic.isEmpty(game) or Logic.isEmpty(player.extradata.heads) then
		return BracketScoreContainer(props)
	end

	return Html.Div{
		css = {
			display = 'flex',
			['align-items'] = 'center',
		},
		children = Array.map(player.extradata.heads, function (headData)
			return Html.Span{
				css = {opacity = headData.status == 0 and 0.3 or nil},
				children = Characters.GetIconAndName{headData.name, game = game}
			}
		end)
	}
end

return Component.component(SmashBracketScoreContainer)
