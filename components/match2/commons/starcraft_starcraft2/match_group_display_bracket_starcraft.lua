---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Bracket/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BracketDisplay = Lua.import('Module:MatchGroup/Display/Bracket', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
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
		})
	})
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
		:addClass(showRaceBackground and Faction.bgClass(opponent.players[1].race) or nil)
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

return StarcraftBracketDisplay
