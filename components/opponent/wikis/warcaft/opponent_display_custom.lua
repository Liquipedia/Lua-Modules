---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:OpponentDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local Opponent = Lua.import('Module:Opponent/Custom', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom', {requireDevIfEnabled = true})
local PlayerDisplay = Lua.import('Module:Player/Display/Custom', {requireDevIfEnabled = true})--todo:create
local Race = Lua.import('Module:Race', {requireDevIfEnabled = true})

local CustomOpponentDisplay = {propTypes = {}, types={}}

CustomOpponentDisplay.propTypes.InlineOpponent = {
	flip = 'boolean?',
	opponent = MatchGroupUtil.types.GameOpponent,
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showRace = 'boolean?',
	teamStyle = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
}

function CustomOpponentDisplay.InlineOpponent(props)
	DisplayUtil.assertPropTypes(props, CustomOpponentDisplay.propTypes.InlineOpponent)
	local opponent = props.opponent

	if Opponent.partySize((opponent or {}).type) then -- opponent.type == 'solo' 'duo' 'trio' 'quad'
		return CustomOpponentDisplay.InlinePlayers(props)
	end

	return OpponentDisplay.InlineOpponent(props)
end

CustomOpponentDisplay.propTypes.BlockOpponent = {
	flip = 'boolean?',
	opponent = MatchGroupUtil.types.GameOpponent,
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showPlayerTeam = 'boolean?',
	showRace = 'boolean?',
	teamStyle = TypeUtil.optional(OpponentDisplay.types.TeamStyle),
	playerClass = 'string?',
	abbreviateTbd = 'boolean?',
}

function CustomOpponentDisplay.BlockOpponent(props)
	DisplayUtil.assertPropTypes(props, CustomOpponentDisplay.propTypes.BlockOpponent)
	local opponent = props.opponent

	opponent.extradata = opponent.extradata or {}
	-- Default TBDs to not show links
	local showLink = Logic.nilOr(props.showLink, not CustomOpponentDisplay.isTbd(opponent))

	if opponent.type == 'literal' and opponent.extradata.hasRaceOrFlag then
		props.showRace = false
		return CustomOpponentDisplay.BlockPlayers(Table.merge(props, {showLink = showLink}))
	elseif Opponent.partySize((opponent or {}).type) then -- opponent.type == 'solo' 'duo' 'trio' 'quad'
		return CustomOpponentDisplay.BlockPlayers(Table.merge(props, {showLink = showLink}))
	end

	return OpponentDisplay.BlockOpponent(props)
end

function CustomOpponentDisplay.InlinePlayers(props)
	local showRace = props.showRace ~= false
	local opponent = props.opponent

	local playerTexts = Array.map(opponent.players, function(player)
		return tostring(PlayerDisplay.InlinePlayer(Table.merge(props, {player = player, showRace = showRace})))
	end)

	if props.flip then
		playerTexts = Array.reverse(playerTexts)
	end

	return mw.html.create('span')
		:node(table.concat(playerTexts, ' / '))
end

function CustomOpponentDisplay.BlockPlayers(props)
	local opponent = props.opponent
	local showRace = props.showRace ~= false

	local playerNodes = Array.map(opponent.players, function(player)
		return PlayerDisplay.BlockPlayer(Table.merge(props, {team = player.team, player = player, showRace = showRace}))
			:addClass(props.playerClass)
	end)

	local playersNode = mw.html.create('div')
		:addClass(props.showPlayerTeam and 'player-has-team' or nil)

	for _, playerNode in ipairs(playerNodes) do
		playersNode:node(playerNode)
	end

	return playersNode
end

return CustomOpponentDisplay
