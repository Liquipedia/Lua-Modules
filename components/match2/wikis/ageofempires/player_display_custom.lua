---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Player/Display/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local OpponentLibraries = require('Module:OpponentLibraries')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Abbreviation = require('Module:Abbreviation')

local Opponent = OpponentLibraries.Opponent
local PlayerDisplay = Lua.import('Module:Player/Display')
local CivIcon = Lua.import('Module:CivIcon')

local TBD_ABBREVIATION = Abbreviation.make('TBD', 'To be determined (or to be decided)')
local ZERO_WIDTH_SPACE = '&#8203;'

local html = mw.html

local CustomPlayerDisplay = Table.deepCopy(PlayerDisplay)

CustomPlayerDisplay.propTypes.BlockPlayer = {
	dq = 'boolean?',
	flip = 'boolean?',
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	player = Opponent.types.Player,
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showPlayerTeam = 'boolean?',
	showCiv = 'boolean?',
	game = 'string?',
	abbreviateTbd = 'boolean?',
}

--[[
Displays a player as a block element. The width of the component is
determined by its layout context, and not by the player name.
]]
function CustomPlayerDisplay.BlockPlayer(props)
	DisplayUtil.assertPropTypes(props, CustomPlayerDisplay.propTypes.BlockPlayer)
	local player = props.player

	local nameNode = html.create(props.dq and 's' or 'span'):addClass('name')
		:wikitext(
			props.abbreviateTbd and Opponent.playerIsTbd(player) and TBD_ABBREVIATION
			or props.showLink ~= false and player.pageName
			and '[[' .. player.pageName .. '|' .. player.displayName .. ']]'
			or Logic.emptyOr(player.displayName, ZERO_WIDTH_SPACE)
		)
	DisplayUtil.applyOverflowStyles(nameNode, props.overflow or 'ellipsis')

	local flagNode
	if props.showFlag ~= false and player.flag then
		flagNode = PlayerDisplay.Flag(player.flag)
	end

	local civNode
	if props.showCiv ~= false then
		civNode = html.create('span'):addClass('draft faction')
			:wikitext(CivIcon._getImage{[1] = player.civ or '', game = props.game})
	end

	local teamNode
	if props.showPlayerTeam and player.team and player.team:lower() ~= 'tbd' then
		teamNode = html.create('span')
			:wikitext('&nbsp;')
			:node(mw.ext.TeamTemplate.teampart(player.team))
	end

	return html.create('div'):addClass('block-player')
		:addClass(props.flip and 'flipped' or nil)
		:addClass(props.showPlayerTeam and 'has-team' or nil)
		:node(flagNode)
		:node(civNode)
		:node(nameNode)
		:node(teamNode)
end

return CustomPlayerDisplay
