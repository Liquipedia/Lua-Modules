---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/Opponent/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft')

local Component = Lua.import('Module:Widget/Component')

---@class StarcraftBracketOpponentProps: BracketOpponentProps
---@field opponent StarcraftStandardOpponent

---@param props StarcraftBracketOpponentProps
---@return Renderable
local function StarcraftBracketOpponent(props)
	local opponent = props.opponent
	if opponent.type == Opponent.team then
		if props.showTbd ~= false or not Opponent.isTbd(opponent) then
			return OpponentDisplay.BlockTeamContainer{
				showLink = false,
				style = props.forceShortName and 'short' or 'hybrid',
				template = opponent.template or 'tbd',
			}
		end
	elseif Opponent.typeIsParty(opponent.type) then
		return OpponentDisplay.BlockOpponent{
			opponent = opponent,
			overflow = 'ellipsis',
			playerClass = 'starcraft-bracket-block-player',
			showLink = false,
			showTbd = props.showTbd,
		}
	end
	-- Literal opponent type
	return OpponentDisplay.BlockLiteral{
		name = Opponent.toName(opponent),
		overflow = 'ellipsis',
	}
end

return Component.component(StarcraftBracketOpponent)
