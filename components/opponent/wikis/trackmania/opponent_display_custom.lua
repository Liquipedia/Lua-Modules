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

local html = mw.html

--[[
Display component for an opponent entry appearing in a bracket match.
]]
OpponentDisplayCustom.BracketOpponentEntry = Class.new(
	function(self, opponent, options)
		self.content = html.create('div'):addClass('brkts-opponent-entry-left')

		if opponent.type == 'team' then
			self:createTeam(opponent.template or 'tbd', options)
		elseif opponent.type == 'solo' or opponent.type == 'duo' then
			self:createPlayers(opponent)
		elseif opponent.type == 'literal' then
			self:createLiteral(opponent.name or '')
		end

		self.root = html.create('div'):addClass('brkts-opponent-entry')
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

OpponentDisplayCustom.BracketOpponentEntry.createLiteral = OpponentDisplay.BracketOpponentEntry.createLiberal

function OpponentDisplayCustom.BracketOpponentEntry:addScores(opponent)
	local extradata = opponent.extradata or {}
	if not extradata.additionalScores then
		OpponentDisplay.BracketOpponentEntry.addScores(self, opponent)
	else
		local score1Node = OpponentDisplay.BracketScore({
			isWinner = extradata.set1win,
			scoreText = OpponentDisplay.InlineScore(opponent),
		})
		self.root:node(score1Node)

		local score2Node
		if opponent.extradata.score2 or opponent.score2 then
			score2Node = OpponentDisplay.BracketScore({
				isWinner = extradata.set2win,
				scoreText = OpponentDisplayCustom.InlineScore2(opponent),
			})
		end
		self.root:node(score2Node)

		local score3Node
		if opponent.extradata.score3 then
			score3Node = OpponentDisplay.BracketScore({
				isWinner = extradata.set3win,
				scoreText = OpponentDisplayCustom.InlineScore3(opponent),
			})
		end
		self.root:node(score3Node)

		if (opponent.placement2 or opponent.placement or 0) == 1
			or opponent.advances then
			self.content:addClass('brkts-opponent-win')
		end
	end
end

--[[
Displays the second score or status of the opponent, as a string.
]]
function OpponentDisplayCustom.InlineScore2(opponent)
	local score2 = opponent.extradata.score2
	if opponent.status2 == 'S' then
		if opponent.score2 == 0 and Opponent.isTbd(opponent) then
			return ''
		else
			return opponent.score2 ~= -1 and tostring(opponent.score2) or ''
		end
	else
		return opponent.status2 or score2 or ''
	end
end

--[[
Displays the third score or status of the opponent, as a string.
]]
function OpponentDisplayCustom.InlineScore3(opponent)
	local score3 = opponent.extradata.score3
	if opponent.status3 == 'S' then
		if opponent.score3 == 0 and Opponent.isTbd(opponent) then
			return ''
		else
			return opponent.score3 ~= -1 and tostring(opponent.score3) or ''
		end
	else
		return opponent.status3 or score3 or ''
	end
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

	if opponent.type == 'team' then
		return OpponentDisplay.BlockTeamContainer({
			flip = props.flip,
			overflow = props.overflow,
			showLink = showLink,
			style = props.teamStyle,
			template = opponent.template or 'tbd',
		})
	elseif opponent.type == 'literal' then
		return OpponentDisplay.BlockLiteral({
			flip = props.flip,
			name = opponent.name or '',
			overflow = props.overflow,
		})
	elseif opponent.type == 'solo' or opponent.type == 'duo' then
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

	return html.create('span')
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
		local playersNode = html.create('div')
			:addClass(props.showPlayerTeam and 'player-has-team' or nil)
		for _, playerNode in ipairs(playerNodes) do
			playersNode:node(playerNode)
		end
		return playersNode
	end
end

return Class.export(OpponentDisplayCustom)
