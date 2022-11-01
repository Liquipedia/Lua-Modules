---
-- @Liquipedia
-- wiki=fortnite
-- page=Module:OpponentDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
local PlayerDisplay = Lua.import('Module:Player/Display', {requireDevIfEnabled = true})

local html = mw.html

--[[
Display components for opponents used by the Fortnite wiki
]]
local FortniteOpponentDisplay = {propTypes = {}, types={}}

--[[
Displays an opponent as an inline element. Useful for describing opponents in
prose.
]]
function FortniteOpponentDisplay.InlineOpponent(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.InlineOpponent)
	local opponent = props.opponent

	if opponent.type == 'team' then
		return OpponentDisplay.InlineTeamContainer({
			flip = props.flip,
			showLink = props.showLink,
			style = props.teamStyle,
			team = opponent.team,
			template = opponent.template or 'tbd',
		})
	elseif opponent.type == 'literal' then
		return OpponentDisplay.InlineOpponent(props)
	else -- opponent.type == 'solo' 'duo' 'trio' 'quad'
		return FortniteOpponentDisplay.PlayerInlineOpponent(props)
	end
end

--[[
Displays an opponent as a block element. The width of the component is
determined by its layout context, and not of the opponent.
]]
function FortniteOpponentDisplay.BlockOpponent(props)
	DisplayUtil.assertPropTypes(props, OpponentDisplay.propTypes.BlockOpponent)
	local opponent = props.opponent
	opponent.extradata = opponent.extradata or {}
	-- Default TBDs to not show links
	local showLink = Logic.nilOr(props.showLink, not Opponent.isTbd(opponent))

	if opponent.type == 'team' then
		return OpponentDisplay.BlockTeamContainer({
			flip = props.flip,
			overflow = props.overflow,
			showLink = showLink,
			style = props.teamStyle,
			team = opponent.team,
			template = opponent.template or 'tbd',
		})
	elseif opponent.type == 'literal' then
		return OpponentDisplay.BlockOpponent(props)
	else -- opponent.type == 'solo' 'duo' 'trio' 'quad'
		return FortniteOpponentDisplay.PlayerBlockOpponent(
			Table.merge(props, {showLink = showLink})
		)
	end
end

--[[
Displays a player opponent (solo, duo, trio, or quad) as an inline element.
]]
function FortniteOpponentDisplay.PlayerInlineOpponent(props)
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

	return html.create('span')
		:node(table.concat(playerTexts, ' / '))
end

--[[
Displays a player opponent (solo, duo, trio, or quad) as a block element.
]]
function FortniteOpponentDisplay.PlayerBlockOpponent(props)
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

return FortniteOpponentDisplay
