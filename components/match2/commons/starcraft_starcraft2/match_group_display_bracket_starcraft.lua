---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Bracket/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local StarcraftMatchGroupUtil = require('Module:MatchGroup/Util/Starcraft')
local Table = require('Module:Table')

local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
local RaceColor = Lua.loadDataIfExists('Module:RaceColorClass') or {}
local StarcraftMatchSummary = Lua.import('Module:MatchSummary/Starcraft', {requireDevIfEnabled = true})
local StarcraftOpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true})

local html = mw.html

local StarcraftBracketDisplay = {propTypes = {}}

function StarcraftBracketDisplay.BracketContainer(props)
	local bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId)
	return BracketDisplay.Bracket({
		bracket = bracket,
		config = Table.merge(props.config, {
			MatchSummaryContainer = StarcraftMatchSummary.MatchSummaryContainer,
			OpponentEntry = StarcraftBracketDisplay.OpponentEntry,
			matchHasDetails = StarcraftMatchGroupUtil.matchHasDetails,
			opponentHeight = StarcraftBracketDisplay.computeBracketOpponentHeight(bracket.matchesById),
		})
	})
end

local defaultOpponentHeights = {
	solo = 17 + 6,
	duo = 2 * 17 + 6 + 4,
	trio = 3 * 17 + 6,
	quad = 4 * 17 + 6,
	team = 17 + 6,
	literal = 17 + 6,
}
function StarcraftBracketDisplay.computeBracketOpponentHeight(matchesById)
	local maxHeight = 10
	for _, match in pairs(matchesById) do
		for _, opponent in ipairs(match.opponents) do
			maxHeight = math.max(maxHeight, defaultOpponentHeights[opponent.type] or 0)
		end
	end
	return maxHeight
end

function StarcraftBracketDisplay.OpponentEntry(props)
	local opponent = props.opponent

	local showRaceBackground = opponent.type == 'solo'
		or opponent.extradata.hasRaceOrFlag
		or opponent.type == 'duo' and opponent.isArchon

	-- Temporary workaround for lpdb bug misplacing players in match2opponent
	if #opponent.players == 0 then
		showRaceBackground = false
	end

	local isWinner = (opponent.placement2 or opponent.placement or 0) == 1
		or opponent.advances

	local leftNode = html.create('div'):addClass('brkts-opponent-entry-left')
		:addClass(showRaceBackground and RaceColor[opponent.players[1].race] or nil)
		:addClass(isWinner and 'brkts-opponent-win' or nil)

	if opponent.type == 'team' then
		local bracketNode = StarcraftOpponentDisplay.BlockTeamContainer({
			overflow = 'ellipsis',
			showLink = false,
			style = 'bracket',
			team = opponent.team,
			template = opponent.template,
		})
		local shortNode = StarcraftOpponentDisplay.BlockTeamContainer({
			overflow = 'hidden',
			showLink = false,
			style = 'short',
			team = opponent.team,
			template = opponent.template,
		})
		leftNode
			:node(bracketNode:addClass('hidden-xs'))
			:node(shortNode:addClass('visible-xs'))
	else
		local blockOpponentNode = StarcraftOpponentDisplay.BlockOpponent({
			opponent = opponent,
			overflow = 'ellipsis',
			playerClass = 'starcraft-bracket-block-player',
			showLink = false,
			showRace = not showRaceBackground,
		})
		leftNode:node(blockOpponentNode)
	end

	local scoreNode
	if props.displayType == 'bracket' then
		scoreNode = OpponentDisplay.BracketScore({
			isWinner = opponent.placement == 1 or opponent.advances,
			scoreText = StarcraftOpponentDisplay.InlineScore(opponent),
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

	return html.create('div'):addClass('brkts-opponent-entry')
		:node(leftNode)
		:node(scoreNode)
		:node(score2Node)
		:node(contestNode)
end

return Class.export(StarcraftBracketDisplay)
