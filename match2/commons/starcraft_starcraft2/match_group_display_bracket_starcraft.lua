local BracketDisplay = require('Module:MatchGroup/Display/Bracket')
local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Lua = require('Module:Lua')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local OpponentDisplay = require('Module:OpponentDisplay')
local StarcraftMatchGroupUtil = require('Module:MatchGroup/Util/Starcraft')
local StarcraftOpponentDisplay = require('Module:OpponentDisplay/Starcraft')
local Table = require('Module:Table')

local RaceColor = Lua.loadDataIfExists('Module:RaceColorClass') or {}

local html = mw.html

local StarcraftBracketDisplay = {propTypes = {}}

function StarcraftBracketDisplay.luaGet(_, args)
	return StarcraftBracketDisplay.BracketContainer({
		bracketId = args[1],
		config = BracketDisplay.configFromArgs(args),
	})
end

function StarcraftBracketDisplay.BracketContainer(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.BracketContainer)
	return StarcraftBracketDisplay.Bracket({
		config = props.config,
		bracket = MatchGroupUtil.fetchMatchGroup(props.bracketId),
	})
end

function StarcraftBracketDisplay.Bracket(props)
	DisplayUtil.assertPropTypes(props, BracketDisplay.propTypes.Bracket)
	return BracketDisplay.Bracket({
		bracket = props.bracket,
		config = Table.merge(props.config, {
			MatchSummaryContainer = require('Module:MatchSummary/Starcraft').MatchSummaryContainer,
			OpponentEntry = StarcraftBracketDisplay.OpponentEntry,
			matchHasDetails = StarcraftMatchGroupUtil.matchHasDetails,
			opponentHeight = StarcraftBracketDisplay.computeBracketOpponentHeight(props.bracket.matchesById),
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
		or opponent.type == 'duo' and opponent.isArchon

	-- Temporary workaround for lpdb bug misplacing players in match2opponent
	if #opponent.players == 0 then
		showRaceBackground = false
	end

	local leftNode = html.create('div'):addClass('brkts-opponent-entry-left')
		:addClass(showRaceBackground and RaceColor[opponent.players[1].race] or nil)

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

	local isWinner = (opponent.placement2 or opponent.placement or 0) == 1
		or opponent.advances

	return html.create('div'):addClass('brkts-opponent-entry')
		:addClass(isWinner and 'brkts-opponent-win' or nil)
		:node(leftNode)
		:node(scoreNode)
		:node(score2Node)
		:node(contestNode)
end

return Class.export(StarcraftBracketDisplay)
