local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PlayerDisplay = require('Module:Player/Display')
local StarcraftMatchGroupUtil = require('Module:MatchGroup/Util/Starcraft')
local StarcraftPlayerUtil = require('Module:Player/Util/Starcraft')
local String = require('Module:StringUtils')
local TypeUtil = require('Module:TypeUtil')

local RaceIcon = Lua.requireIfExists('Module:RaceIcon') or {
	getSmallIcon = function() end,
}

local html = mw.html

--[[
Display components for players used in the starcraft and starcraft2 wikis.
]]
local StarcraftPlayerDisplay = {propTypes = {}}

StarcraftPlayerDisplay.propTypes.BlockPlayer = {
	flip = 'boolean?',
	overflow = TypeUtil.optional(DisplayUtil.types.OverflowModes),
	player = StarcraftMatchGroupUtil.types.Player,
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showRace = 'boolean?',
}

--[[
Displays a player as a block element. The width of the component is
determined by its layout context, and not by the player name.
]]
function StarcraftPlayerDisplay.BlockPlayer(props)
	DisplayUtil.assertPropTypes(props, StarcraftPlayerDisplay.propTypes.BlockPlayer)
	local player = props.player

	local nameNode = html.create('span'):addClass('name')
		:wikitext(props.showLink ~= false and player.pageName
			and '[[' .. player.pageName .. '|' .. player.displayName .. ']]'
			or player.displayName
		)
	DisplayUtil.applyOverflowStyles(nameNode, props.overflow or 'ellipsis')

	local flagNode
	if props.showFlag ~= false and player.flag then
		flagNode = PlayerDisplay.Flag(player.flag)
	end

	local raceNode
	if props.showRace ~= false and player.race ~= 'u' then
		raceNode = html.create('span'):addClass('race')
			:wikitext(StarcraftPlayerDisplay.Race(player.race))
	end

	return html.create('div'):addClass('block-player starcraft-block-player')
		:addClass(props.flip and 'flipped' or nil)
		:node(flagNode)
		:node(raceNode)
		:node(nameNode)
end

-- Called from Template:Player and Template:Player2
function StarcraftPlayerDisplay.TemplatePlayer(frame)
	local args = require('Module:Arguments').getArgs(frame)

	local pageName
	local displayName
	if not args.noclean then
		pageName, displayName = StarcraftPlayerUtil.extractFromLink(args[1])
		if args.link == 'true' then
			pageName = displayName
		elseif args.link then
			pageName = args.link
		end
	else
		pageName = args.link
		displayName = args[1]
	end

	local player = {
		displayName = displayName,
		flag = String.nilIfEmpty(args.flag),
		pageName = pageName,
		race = String.nilIfEmpty(args.race) or 'u',
	}

	if not args.novar then
		StarcraftPlayerUtil.saveToPageVars(player)
	end

	local hiddenSortNode = args.hs
		and StarcraftPlayerUtil.HiddenSort(player.displayName, player.flag, player.race, args.hs)
		or ''
	local playerNode = StarcraftPlayerDisplay.InlinePlayer({
		dq = Logic.readBoolOrNil(args.dq),
		flip = Logic.readBoolOrNil(args.flip),
		player = player,
		showRace = (args.showRace or 'true') == 'true',
	})
	return tostring(hiddenSortNode) .. tostring(playerNode)
end

-- Called from Template:InlinePlayer
function StarcraftPlayerDisplay.TemplateInlinePlayer(frame)
	local args = require('Module:Arguments').getArgs(frame)

	local player = {
		displayName = args[1],
		flag = args.flag,
		pageName = args.link,
		race = StarcraftPlayerUtil.readRace(args.race),
	}
	return StarcraftPlayerDisplay.InlinePlayerContainer({
		date = args.date,
		dontSave = Logic.readBoolOrNil(args.novar),
		dq = Logic.readBoolOrNil(args.dq),
		flip = Logic.readBoolOrNil(args.flip),
		player = player,
		showFlag = Logic.readBoolOrNil(args.showFlag),
		showLink = Logic.readBoolOrNil(args.showLink),
		showRace = Logic.readBoolOrNil(args.showRace),
	})
end

StarcraftPlayerDisplay.propTypes.InlinePlayerContainer = {
	date = 'string?',
	dontSave = 'boolean?',
	dq = 'boolean?',
	flip = 'boolean?',
	player = 'table',
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showRace = 'boolean?',
}

--[[
Displays a player as an inline element. Useful for referencing players in
prose. This container will automatically look up the pageName, race, and flag
of the player from page variables or LPDB, and save the results to page
variables.
]]
function StarcraftPlayerDisplay.InlinePlayerContainer(props)
	DisplayUtil.assertPropTypes(props, StarcraftPlayerDisplay.propTypes.InlinePlayerContainer)
	StarcraftPlayerUtil.syncPlayer(props.player, props.date, props.dontSave)

	return StarcraftPlayerDisplay.InlinePlayer(props)
end

--[[
Displays a player as an inline element. Useful for referencing players in
prose.
]]
StarcraftPlayerDisplay.propTypes.InlinePlayer = {
	dq = 'boolean?',
	flip = 'boolean?',
	player = StarcraftMatchGroupUtil.types.Player,
	showFlag = 'boolean?',
	showLink = 'boolean?',
	showRace = 'boolean?',
}
function StarcraftPlayerDisplay.InlinePlayer(props)
	DisplayUtil.assertPropTypes(props, StarcraftPlayerDisplay.propTypes.InlinePlayer)
	local player = props.player

	local flag = props.showFlag ~= false and player.flag
		and PlayerDisplay.Flag(player.flag)
		or nil

	local race = props.showRace ~= false and player.race ~= 'u'
		and StarcraftPlayerDisplay.Race(player.race)
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

	return html.create('span'):addClass('starcraft-inline-player')
		:addClass(props.flip and 'flipped' or nil)
		:wikitext(text)
end

function StarcraftPlayerDisplay.HiddenSort(name, flag, race, field)
	local text
	if field == 'race' then
		text = race
	elseif field == 'name' then
		text = name
	elseif field == 'flag' then
		text = flag
	else
		text = field
	end

	return html.create('span')
		:css('display', 'none')
		:wikitext(text)
end

function StarcraftPlayerDisplay.Race(race)
	return DisplayUtil.removeLinkFromWikiLink(
		RaceIcon.getSmallIcon({race})
	)
end

return Class.export(StarcraftPlayerDisplay)
