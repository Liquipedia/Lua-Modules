---
-- @Liquipedia
-- wiki=tetris
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

CustomOpponentDisplay.BracketOpponentEntry = Class.new(OpponentDisplay.BracketOpponentEntry,
	function(self, opponent, options)
		if opponent.type == Opponent.duo then
			self:createDuo(opponent)
		end

		self.root = mw.html.create('div'):addClass('brkts-opponent-entry')
			:node(self.content)
	end
)

function CustomOpponentDisplay.BracketOpponentEntry:createDuo(opponent)
	local playerNode = CustomOpponentDisplay.BlockPlayers({
		opponent = opponent,
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
		return CustomOpponentDisplay.BlockPlayers(props)
	end

	return OpponentDisplay.BlockOpponent(props)
end

function CustomOpponentDisplay.BlockPlayers(props)
	local opponent = props.opponent

	local playerNodes = Array.map(opponent.players, function(player)
		return PlayerDisplay.BlockPlayer(Table.merge(props, {player = player, team = player.team}))
	end)

	local playersNode = mw.html.create('div')
		:addClass(props.showPlayerTeam and 'player-has-team' or nil)
	for _, playerNode in ipairs(playerNodes) do
		playersNode:node(playerNode)
	end

	return playersNode
end

function CustomOpponentDisplay.InlineOpponent(props)
	DisplayUtil.assertPropTypes(props, CustomOpponentDisplay.propTypes.InlineOpponent, {maxDepth = 2})
	local opponent = props.opponent

	if opponent.type == Opponent.duo then
		return CustomOpponentDisplay.InlinePlayers(props)
	end

	return OpponentDisplay.InlineOpponent(props)
end

function CustomOpponentDisplay.InlinePlayers(props)
	local opponent = props.opponent

	local playerTexts = Array.map(opponent.players, function(player)
		return tostring(PlayerDisplay.InlinePlayer(Table.merge(props, {player = player})))
	end)

	if props.flip then
		playerTexts = Array.reverse(playerTexts)
	end

	return mw.html.create('span')
		:node(table.concat(playerTexts, ' / '))
end

return Class.export(CustomOpponentDisplay)
