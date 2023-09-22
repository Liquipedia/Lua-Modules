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
local MatchSummary = Lua.import('Module:MatchSummary', {requireDevIfEnabled = true})

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local html = mw.html

local CustomBracketDisplay = {}

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

function CustomBracketDisplay.OpponentEntry(props)
	local opponent = props.opponent

	local showRaceBackground = opponent.type == Opponent.solo
		or opponent.extradata.hasRaceOrFlag

	local isWinner = (opponent.placement2 or opponent.placement or 0) == 1
		or opponent.advances

	local leftNode = html.create('div'):addClass('brkts-opponent-entry-left')
		:addClass(showRaceBackground and Faction.bgClass(opponent.players[1].race) or nil)
		:addClass(isWinner and 'brkts-opponent-win' or nil)

	if opponent.type == Opponent.team then
		local bracketNode = OpponentDisplay.BlockTeamContainer({
			overflow = 'ellipsis',
			showLink = false,
			style = 'bracket',
			team = opponent.team,
			template = opponent.template,
		})
		local shortNode = OpponentDisplay.BlockTeamContainer({
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
		local blockOpponentNode = OpponentDisplay.BlockOpponent({
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

	return html.create('div'):addClass('brkts-opponent-entry')
		:node(leftNode)
		:node(scoreNode)
		:node(score2Node)
		:node(contestNode)
end

return CustomBracketDisplay
