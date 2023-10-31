---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Player/Display/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local DisplayUtil = require('Module:DisplayUtil')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local TypeUtil = require('Module:TypeUtil')

local CustomMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local PlayerDisplay = Lua.import('Module:Player/Display', {requireDevIfEnabled = true})
local PlayerExt = Lua.import('Module:Player/Ext/Custom', {requireDevIfEnabled = true})

local TBD_ABBREVIATION = Abbreviation.make('TBD', 'To be determined (or to be decided)')
local ZERO_WIDTH_SPACE = '&#8203;'

local CustomPlayerDisplay = {propTypes = {}}

CustomPlayerDisplay.propTypes.BlockPlayer = {
	dq = 'boolean?',
	flip = 'boolean?',
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	player = CustomMatchGroupUtil.types.Player,
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showPlayerTeam = 'boolean?',
	showRace = 'boolean?',
	abbreviateTbd = 'boolean?',
	note = 'string?',
}

function CustomPlayerDisplay.BlockPlayer(props)
	DisplayUtil.assertPropTypes(props, CustomPlayerDisplay.propTypes.BlockPlayer)
	local player = props.player

	local nameNode = mw.html.create(props.dq and 's' or 'span')
		:wikitext(
			props.abbreviateTbd and Opponent.playerIsTbd(player) and TBD_ABBREVIATION
			or props.showLink ~= false and player.pageName
			and '[[' .. player.pageName .. '|' .. player.displayName .. ']]'
			or Logic.emptyOr(player.displayName, ZERO_WIDTH_SPACE)
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

	local raceNode
	if props.showRace ~= false and player.race ~= Faction.defaultFaction then
		raceNode = mw.html.create('span'):addClass('race')
			:wikitext(CustomPlayerDisplay.Race(player.race))
	end

	local teamNode
	if props.showPlayerTeam and player.team and player.team:lower() ~= 'tbd' then
		teamNode = mw.html.create('span')
			:wikitext('&nbsp;')
			:node(mw.ext.TeamTemplate.teampart(player.team))
	end

	return mw.html.create('div'):addClass('block-player starcraft-block-player')
		:addClass(props.flip and 'flipped' or nil)
		:addClass(props.showPlayerTeam and 'has-team' or nil)
		:node(flagNode)
		:node(raceNode)
		:node(nameNode)
		:node(teamNode)
end

CustomPlayerDisplay.propTypes.InlinePlayerContainer = {
	date = 'string?',
	dq = 'boolean?',
	flip = 'boolean?',
	player = 'table',
	savePageVar = 'boolean?',
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showRace = 'boolean?',
}

function CustomPlayerDisplay.InlinePlayerContainer(props)
	DisplayUtil.assertPropTypes(props, CustomPlayerDisplay.propTypes.InlinePlayerContainer)
	PlayerExt.syncPlayer(props.player, {
		date = props.date,
		savePageVar = props.savePageVar,
	})

	return CustomPlayerDisplay.InlinePlayer(props)
end

CustomPlayerDisplay.propTypes.InlinePlayer = {
	dq = 'boolean?',
	flip = 'boolean?',
	player = CustomMatchGroupUtil.types.Player,
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showRace = 'boolean?',
}
function CustomPlayerDisplay.InlinePlayer(props)
	DisplayUtil.assertPropTypes(props, CustomPlayerDisplay.propTypes.InlinePlayer)
	local player = props.player

	local flag = props.showFlag ~= false and player.flag
		and PlayerDisplay.Flag(player.flag)
		or nil

	local race = props.showRace ~= false and player.race ~= Faction.defaultFaction
		and CustomPlayerDisplay.Race(player.race)
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
			.. (race and '&nbsp;' .. race or '')
			.. (flag and '&nbsp;' .. flag or '')
	else
		text = (flag and flag .. '&nbsp;' or '')
			.. (race and race .. '&nbsp;' or '')
			.. nameAndLink
	end

	return mw.html.create('span'):addClass('starcraft-inline-player')
		:addClass(props.flip and 'flipped' or nil)
		:wikitext(text)
end

function CustomPlayerDisplay.Race(race)
	return Faction.Icon{size = 'small', showLink = false, showTitle = false, faction = race}
end

return CustomPlayerDisplay
