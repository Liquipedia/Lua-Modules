---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:OpponentDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
local PlayerDisplay = Lua.import('Module:Player/Display', {requireDevIfEnabled = true})

local OpponentDisplayCustom = Table.deepCopy(OpponentDisplay)

local SCORE_STATUS = 'S'
local NO_SCORE = -1
local ZERO_SCORE = 0

--[[
Display component for an opponent entry appearing in a bracket match.
]]
OpponentDisplayCustom.BracketOpponentEntry = Class.new(
	function(self, opponent, options)
		self.content = mw.html.create('div'):addClass('brkts-opponent-entry-left')

		if opponent.type == Opponent.team then
			self:createTeam(opponent.template or 'tbd', options)
		elseif opponent.type == Opponent.solo or opponent.type == Opponent.duo then
			self:createPlayers(opponent)
		elseif opponent.type == Opponent.literal then
			self:createLiteral(opponent.name or '')
		end

		self.root = mw.html.create('div'):addClass('brkts-opponent-entry')
			:node(self.content)
	end
)

OpponentDisplayCustom.BracketOpponentEntry.createTeam = OpponentDisplay.BracketOpponentEntry.createTeam

function OpponentDisplayCustom.BracketOpponentEntry:createPlayers(opponent)
	local players = opponent.players
	if #players == 1 then
		local playerNode = PlayerDisplay.BlockPlayer({
			player = players[1],
			overflow = 'ellipsis',
		})
		self.content:node(playerNode)
	else
		local playersNode = OpponentDisplayCustom.PlayerInlineOpponent{
			opponent = opponent
		}

		self.content:node(playersNode)
	end
end

OpponentDisplayCustom.BracketOpponentEntry.createLiteral = OpponentDisplay.BracketOpponentEntry.createLiteral

function OpponentDisplayCustom.BracketOpponentEntry:addScores(opponent)
	local extradata = opponent.extradata or {}
	if not extradata.additionalScores then
		OpponentDisplay.BracketOpponentEntry.addScores(self, opponent)
	else
		self.root:node(OpponentDisplay.BracketScore{
			isWinner = extradata.set1win,
			scoreText = OpponentDisplayCustom.InlineScore(opponent, ''),
		})
		if opponent.extradata.score2 or opponent.score2 then
			self.root:node(OpponentDisplay.BracketScore{
				isWinner = extradata.set2win,
				scoreText = OpponentDisplayCustom.InlineScore(opponent, 2),
			})
		end
		if opponent.extradata.score3 then
			self.root:node(OpponentDisplay.BracketScore{
				isWinner = extradata.set3win,
				scoreText = OpponentDisplayCustom.InlineScore(opponent, 3)
			})
		end
		if (opponent.placement2 or opponent.placement or 0) == 1
			or opponent.advances then
			self.content:addClass('brkts-opponent-win')
		end
	end
end
function OpponentDisplayCustom.InlineScore(opponent, scoreIndex)
	scoreIndex = scoreIndex or ''
	local status = opponent['status' .. scoreIndex] or opponent.extradata['status' .. scoreIndex] or ''
	local score = opponent['score' .. scoreIndex] or opponent.extradata['score' .. scoreIndex] or 0
	if status == SCORE_STATUS then
		if (score == ZERO_SCORE and Opponent.isTbd(opponent)) or score == NO_SCORE then
			return ''
		else
			return score ~= -1 and tostring(score) or ''
		end
	end
	return score or status or ''
end

--[[
Displays an opponent as a block element. The width of the component is
determined by its layout context, and not of the opponent.
]]
function OpponentDisplayCustom.BlockOpponent(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockOpponent, {maxDepth = 2})
	local opponent = props.opponent
	-- Default TBDs to not show links
	local showLink = Logic.nilOr(props.showLink, not Opponent.isTbd(opponent))

	if opponent.type == Opponent.team then
		return OpponentDisplay.BlockTeamContainer({
			flip = props.flip,
			overflow = props.overflow,
			showLink = showLink,
			style = props.teamStyle,
			template = opponent.template or 'tbd',
		})
	elseif opponent.type == Opponent.literal then
		return OpponentDisplay.BlockLiteral({
			flip = props.flip,
			name = opponent.name or '',
			overflow = props.overflow,
		})
	elseif opponent.type == Opponent.solo or opponent.type == Opponent.duo then
		return OpponentDisplayCustom.PlayerBlockOpponent(
			Table.merge(props, {showLink = showLink})
		)
	else
		error('Unrecognized opponent.type ' .. opponent.type)
	end
end

--[[
Displays a player opponent (solo or duo) as an inline element.
]]
function OpponentDisplayCustom.PlayerInlineOpponent(props)
	local opponent = props.opponent

	local playerTexts = Array.map(opponent.players, function(player)
		local node = PlayerDisplay.InlinePlayer({
			flip = props.flip,
			player = player,
			showFlag = props.showFlag,
			showLink = props.showLink
		})
		return tostring(node)
	end)
	if props.flip then
		playerTexts = Array.reverse(playerTexts)
	end

	local playersNode = table.concat(playerTexts, ' / ')

	return mw.html.create('span')
		:node(playersNode)
end

--[[
Displays a player opponent (solo or duo) as a block element.
]]
function OpponentDisplayCustom.PlayerBlockOpponent(props)
	local opponent = props.opponent

	local playerNodes = Array.map(opponent.players, function(player)
		return PlayerDisplay.BlockPlayer({
			flip = props.flip,
			overflow = props.overflow,
			player = player,
			showFlag = props.showFlag,
			showLink = props.showLink,
			showPlayerTeam = props.showPlayerTeam,
			team = player.team,
			abbreviateTbd = props.abbreviateTbd
		})
			:addClass(props.playerClass)
	end)

	if #opponent.players == 1 then
		return playerNodes[1]
	else
		local playersNode = mw.html.create('div')
			:addClass(props.showPlayerTeam and 'player-has-team' or nil)
		for _, playerNode in ipairs(playerNodes) do
			playersNode:node(playerNode)
		end
		return playersNode
	end
end

return Class.export(OpponentDisplayCustom)
