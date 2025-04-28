---
-- @Liquipedia
-- wiki=smash
-- page=Module:MatchGroup/Display/Bracket/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Characters = require('Module:Characters')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local CustomBracketDisplay = {propTypes = {}}

---@param props {bracketId: string, config: BracketConfigOptions}
---@return Html
function CustomBracketDisplay.BracketContainer(props)
	return BracketDisplay.Bracket({
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId) --[[@as MatchGroupUtilBracket]],
		config = Table.merge(props.config, {
			OpponentEntry = CustomBracketDisplay.OpponentEntry,
		})
	})
end

---@param props {opponent: SmashStandardOpponent, displayType: string, matchWidth: number}
---@return Html
function CustomBracketDisplay.OpponentEntry(props)
	local opponentEntry = OpponentDisplay.BracketOpponentEntry(props.opponent)
	if props.displayType == 'bracket' and props.opponent.type == Opponent.solo then
		CustomBracketDisplay._addHeads(opponentEntry, props.opponent)
		if props.opponent.placement == 1 then
			opponentEntry.content:addClass('brkts-opponent-win')
		end
	elseif props.displayType == 'bracket' then
		opponentEntry:addScores(props.opponent)
	end
	return opponentEntry.root
end

---@param opponentEntry BracketOpponentEntry
---@param opponent SmashStandardOpponent
function CustomBracketDisplay._addHeads(opponentEntry, opponent)
	local game = opponent.players[1].game
	local charactersNode = mw.html.create('div'):css('display', 'flex'):css('align-items', 'center')
	Array.forEach(opponent.players[1].heads or {}, function(headData)
		charactersNode:node(
			mw.html.create('span')
				:node(Characters.GetIconAndName{headData.name, game = game})
				:css('opacity', headData.status == 0 and '0.3' or nil)
		)
	end)
	opponentEntry.root:node(charactersNode)
end

return CustomBracketDisplay
