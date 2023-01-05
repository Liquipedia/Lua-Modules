---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:OpponentDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- needed for duo display

local Array = require('Module:Array')
local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

-- can not use Module:OpponentLibraries here due to circular requires
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
local PlayerDisplay = Lua.import('Module:Player/Display', {requireDevIfEnabled = true})

local CustomOpponentDisplay = Table.copy(OpponentDisplay)

CustomOpponentDisplay.BracketOpponentEntry = Class.new(
	function(self, opponent, options)
		self.content = mw.html.create('div'):addClass('brkts-opponent-entry-left')

		if opponent.type == Opponent.team then
			self:createTeam(opponent.template or 'tbd', options)
		elseif opponent.type == Opponent.solo then
			self:createPlayer(opponent.players[1])
		elseif opponent.type == Opponent.duo then
			self:createDuo(opponent)
		elseif opponent.type == Opponent.literal then
			self:createLiteral(opponent.name or '')
		end

		self.root = mw.html.create('div'):addClass('brkts-opponent-entry')
			:node(self.content)
	end
)

CustomOpponentDisplay.BracketOpponentEntry.createTeam = OpponentDisplay.BracketOpponentEntry.createTeam
CustomOpponentDisplay.BracketOpponentEntry.createLiteral = OpponentDisplay.BracketOpponentEntry.createLiteral
CustomOpponentDisplay.BracketOpponentEntry.addScores = OpponentDisplay.BracketOpponentEntry.addScores

function CustomOpponentDisplay.BracketOpponentEntry:createDuo(opponent)
	local playerNode = CustomOpponentDisplay.PlayerBlockOpponent({
		opponent = opponent,
		overflow = 'ellipsis',
		showLink = false,
	})
	self.content:node(playerNode)
end

function CustomOpponentDisplay.BracketOpponentEntry:createPlayer(player)
	local playerNode = PlayerDisplay.BlockPlayer({
		player = player,
		overflow = 'ellipsis',
		showLink = false,
	})
	self.content:node(playerNode)
end

function CustomOpponentDisplay.BlockOpponent(props)
	DisplayUtil.assertPropTypes(props, CustomOpponentDisplay.propTypes.BlockOpponent, {maxDepth = 2})
	local opponent = props.opponent

	-- Default TBDs to not show links
	props.showLink = Logic.nilOr(props.showLink, not Opponent.isTbd(opponent))

	if opponent.type == Opponent.duo then
		return CustomOpponentDisplay.PlayerBlockOpponent(props)
	end

	return OpponentDisplay.BlockOpponent(props)
end

function CustomOpponentDisplay.PlayerBlockOpponent(props)
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
			abbreviateTbd = props.abbreviateTbd,
		})
	end)

	if #opponent.players == Opponent.partySize(Opponent.solo) then
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

function CustomOpponentDisplay.InlineOpponent(props)
	DisplayUtil.assertPropTypes(props, CustomOpponentDisplay.propTypes.InlineOpponent, {maxDepth = 2})
	local opponent = props.opponent

	if opponent.type == Opponent.duo then
		return CustomOpponentDisplay.PlayerInlineOpponent(props)
	end

	return OpponentDisplay.InlineOpponent(props)
end

function CustomOpponentDisplay.PlayerInlineOpponent(props)
	local opponent = props.opponent

	local playerTexts = Array.map(opponent.players, function(player)
		local node = PlayerDisplay.InlinePlayer({
			flip = props.flip,
			player = player,
			showFlag = props.showFlag,
			showLink = props.showLink,
		})
		return tostring(node)
	end)

	if props.flip then
		playerTexts = Array.reverse(playerTexts)
	end

	return mw.html.create('span')
		:node(table.concat(playerTexts, ' / '))
end

return Class.export(CustomOpponentDisplay)
