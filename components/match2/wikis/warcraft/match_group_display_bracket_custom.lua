---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:MatchGroup/Display/Bracket/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket', {requireDevIfEnabled = true})
local CustomMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom', {requireDevIfEnabled = true})

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local CustomBracketDisplay = {}

---@param props {bracketId: string, config: table}
---@return Html
function CustomBracketDisplay.BracketContainer(props)
	local bracket = CustomMatchGroupUtil.fetchMatchGroup(props.bracketId)
	return BracketDisplay.Bracket({
		bracket = bracket,
		config = Table.merge(props.config, {
			OpponentEntry = CustomBracketDisplay.OpponentEntry,
			matchHasDetails = CustomMatchGroupUtil.matchHasDetails,
		})
	})
end

---@param props {displayType: string, opponent: WarcraftStandardOpponent, forceShortName: boolean?, height: number?}
---@return Html
function CustomBracketDisplay.OpponentEntry(props)
	local opponent = props.opponent

	local showRaceBackground = opponent.type == Opponent.solo
		or opponent.extradata.hasRaceOrFlag

	local isWinner = (opponent.placement2 or opponent.placement or 0) == 1
		or opponent.advances

	local leftNode = mw.html.create('div'):addClass('brkts-opponent-entry-left')
		:addClass(showRaceBackground and Faction.bgClass(opponent.players[1].race) or nil)
		:addClass(isWinner and 'brkts-opponent-win' or nil)

	if opponent.type == Opponent.team then
		leftNode:node(OpponentDisplay.BlockTeamContainer({
			showLink = false,
			style = 'hybrid',
			team = opponent.team,
			template = opponent.template,
		}))
	else
		leftNode:node(OpponentDisplay.BlockOpponent({
			opponent = opponent,
			overflow = 'ellipsis',
			playerClass = 'starcraft-bracket-block-player',
			showLink = false,
			showRace = not showRaceBackground,
		}))
	end

	local scoreNode
	if props.displayType == 'bracket' then
		scoreNode = OpponentDisplay.BracketScore({
			isWinner = opponent.placement == 1 or opponent.advances,
			scoreText = OpponentDisplay.InlineScore(opponent),
		})
	end

	local score2Node
	if opponent.score2 and props.displayType == 'bracket' then
		score2Node = OpponentDisplay.BracketScore({
			isWinner = opponent.placement2 == 1,
			scoreText = OpponentDisplay.InlineScore2(opponent),
		})
	end

	local contestNode
	if opponent.extradata.contest and props.displayType == 'bracket' then
		contestNode = OpponentDisplay.BracketScore({
			scoreText = opponent.extradata.contest,
		})
	end

	return mw.html.create('div'):addClass('brkts-opponent-entry')
		:node(leftNode)
		:node(scoreNode)
		:node(score2Node)
		:node(contestNode)
end

return CustomBracketDisplay
