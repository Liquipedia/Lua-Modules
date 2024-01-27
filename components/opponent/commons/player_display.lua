---
-- @Liquipedia
-- wiki=commons
-- page=Module:Player/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local TypeUtil = require('Module:TypeUtil')
local Flags = require('Module:Flags')
local Abbreviation = require('Module:Abbreviation')

local Opponent = Lua.import('Module:Opponent')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local TBD_ABBREVIATION = Abbreviation.make('TBD', 'To be determined (or to be decided)')

--[[
Display components for players.
]]
local PlayerDisplay = {propTypes = {}}

PlayerDisplay.propTypes.BlockPlayer = {
	dq = 'boolean?',
	flip = 'boolean?',
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	player = MatchGroupUtil.types.Player,
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showPlayerTeam = 'boolean?',
	abbreviateTbd = 'boolean?',
	note = 'string?',
}

--[[
Displays a player as a block element. The width of the component is
determined by its layout context, and not by the player name.
]]
function PlayerDisplay.BlockPlayer(props)
	DisplayUtil.assertPropTypes(props, PlayerDisplay.propTypes.BlockPlayer)
	local player = props.player

	local zeroWidthSpace = '&#8203;'
	local nameNode = mw.html.create(props.dq and 's' or 'span')
		:wikitext(props.abbreviateTbd and Opponent.playerIsTbd(player) and TBD_ABBREVIATION
			or props.showLink ~= false and Logic.isNotEmpty(player.pageName)
			and '[[' .. player.pageName .. '|' .. player.displayName .. ']]'
			or Logic.emptyOr(player.displayName, zeroWidthSpace)
		)
	DisplayUtil.applyOverflowStyles(nameNode, props.overflow or 'ellipsis')

	if props.note then
		nameNode = mw.html.create('span'):addClass('name')
			:node(nameNode)
			:tag('sup'):addClass('note'):wikitext(props.note):done()
	else
		nameNode:addClass('name')
	end

	local flagNode
	if props.showFlag ~= false and player.flag then
		flagNode = PlayerDisplay.Flag(player.flag)
	end

	local teamNode
	if props.showPlayerTeam and player.team and player.team:lower() ~= 'tbd' then
		teamNode = mw.html.create('span')
			:wikitext('&nbsp;')
			:node(mw.ext.TeamTemplate.teampart(player.team))
	end

	return mw.html.create('div'):addClass('block-player')
		:addClass(props.flip and 'flipped' or nil)
		:addClass(props.showPlayerTeam and 'has-team' or nil)
		:node(flagNode)
		:node(nameNode)
		:node(teamNode)
end

PlayerDisplay.propTypes.InlinePlayer = {
	dq = 'boolean?',
	flip = 'boolean?',
	player = MatchGroupUtil.types.Player,
	showFlag = 'boolean?',
	showLink = 'boolean?',
}

--[[
Displays a player as an inline element. Useful for referencing players in
prose.
]]
function PlayerDisplay.InlinePlayer(props)
	DisplayUtil.assertPropTypes(props, PlayerDisplay.propTypes.InlinePlayer)
	local player = props.player

	local flag = props.showFlag ~= false and player.flag
		and PlayerDisplay.Flag(player.flag)
		or nil

	local nameAndLink = props.showLink ~= false and player.pageName
		and '[[' .. player.pageName .. '|' .. player.displayName .. ']]'
		or player.displayName
	if props.dq then
		nameAndLink = '<s>' .. nameAndLink .. '</s>'
	end

	local text
	if props.flip then
		text = nameAndLink
			.. (flag and ('&nbsp;' .. flag) or '')
	else
		text = (flag and (flag .. '&nbsp;') or '')
			.. nameAndLink
	end

	return mw.html.create('span'):addClass('inline-player')
		:addClass(props.flip and 'flipped' or nil)
		:css('white-space', 'pre')
		:wikitext(text)
end

-- Note: require('Module:Flags').Icon automatically includes a span with class="flag"
function PlayerDisplay.Flag(name)
	return Flags.Icon({flag = name, shouldLink = false})
end

return Class.export(PlayerDisplay)
