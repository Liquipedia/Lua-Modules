---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/OpponentEntry
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Faction = Lua.import('Module:Faction')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local ScoreContainer = Lua.import('Module:Widget/Match/Bracket/ScoreContainer/Custom')

---@class BracketOpponentEntryProps
---@field classes string[]?
---@field opponent standardOpponent
---@field height number
---@field forceShortName boolean?
---@field showTbd boolean?
---@field displayType string

---@param props BracketOpponentEntryProps
---@return VNode
local function createOpponentDisplay(props)
	local opponent = props.opponent
	if opponent.type == Opponent.team then
		if props.showTbd ~= false or not Opponent.isTbd(opponent) then
			return OpponentDisplay.BlockTeamContainer{
				showLink = false,
				style = props.forceShortName and 'short' or 'dynamic',
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

---@param props BracketOpponentEntryProps
---@return VNode
local function BracketOpponentEntry(props)
	local opponent = props.opponent
	local win = (opponent.placement2 or opponent.placement or 0) == 1
		or opponent.advances
	return Html.Div(DisplayHelper.addOpponentHighlightToProps(
		{
			classes = Array.extend(
				'brkts-opponent-entry',
				props.classes
			),
			css = props.height and {height = props.height .. 'px'} or nil,
			children = Html.Div{
				classes = Array.extend(
					'brkts-opponent-entry-left',
					win and 'brkts-opponent-win' or nil,
					opponent.type == Opponent.solo and Faction.bgClass(opponent.players[1].faction) or nil
				),
				children = {
					createOpponentDisplay(props),
					props.displayType == 'bracket' and ScoreContainer(props) or nil
				}
			}
		},
		props.opponent
	))
end

return Component.component(BracketOpponentEntry, {showTbd = false})
