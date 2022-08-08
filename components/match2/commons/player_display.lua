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

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

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
}

--[[
Displays a player as a block element. The width of the component is
determined by its layout context, and not by the player name.
]]
function PlayerDisplay.BlockPlayer(props)
	DisplayUtil.assertPropTypes(props, PlayerDisplay.propTypes.BlockPlayer)
	local player = props.player

	local zeroWidthSpace = '&#8203;'
	local nameNode = mw.html.create(props.dq and 's' or 'span'):addClass('name')
		:wikitext(props.showLink ~= false and player.pageName
			and '[[' .. player.pageName .. '|' .. player.displayName .. ']]'
			or Logic.emptyOr(player.displayName, zeroWidthSpace)
		)
	DisplayUtil.applyOverflowStyles(nameNode, props.overflow or 'ellipsis')

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
