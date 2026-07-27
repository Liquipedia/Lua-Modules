---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/Opponent
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')

local Component = Lua.import('Module:Widget/Component')

---@class BracketOpponentProps
---@field opponent standardOpponent
---@field forceShortName boolean?
---@field showTbd boolean?

---@param props BracketOpponentProps
---@return VNode
local function BracketOpponent(props)
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
		return OpponentDisplay.BlockPlayers{
			opponent = opponent,
			overflow = 'ellipsis',
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

return Component.component(BracketOpponent)
