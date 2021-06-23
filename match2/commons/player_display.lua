local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local MatchGroupUtil = require('Module:MatchGroup/Util')
local TypeUtil = require('Module:TypeUtil')

--[[
Display components for players.
]]
local PlayerDisplay = {propTypes = {}}

PlayerDisplay.propTypes.BlockPlayer = {
	flip = 'boolean?',
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	player = MatchGroupUtil.types.Player,
	showFlag = 'boolean?',
	showLink = 'boolean?',
}

--[[
Displays a player as a block element. The width of the component is
determined by its layout context, and not by the player name.
]]
function PlayerDisplay.BlockPlayer(props)
	DisplayUtil.assertPropTypes(props, PlayerDisplay.propTypes.BlockPlayer)
	local player = props.player

	local nameNode = mw.html.create('span'):addClass('name')
		:wikitext(props.showLink ~= false and player.pageName
			and '[[' .. player.pageName .. '|' .. player.displayName .. ']]'
			or player.displayName
		)
	DisplayUtil.applyOverflowStyles(nameNode, props.overflow or 'ellipsis')

	local flagNode
	if props.showFlag ~= false and player.flag then
		flagNode = PlayerDisplay.Flag(player.flag)
	end

	return mw.html.create('div'):addClass('block-player')
		:addClass(props.flip and 'flipped' or nil)
		:node(flagNode)
		:node(nameNode)
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

-- Note: require('Module:Flag')[flag] automatically includes a span with class="flag"
function PlayerDisplay.Flag(flag)
	flag = flag:lower()
	return require('Module:Flag')[flag]
		or mw.getCurrentFrame():expandTemplate{ title = 'Flag/' .. flag }
end

return Class.export(PlayerDisplay)
