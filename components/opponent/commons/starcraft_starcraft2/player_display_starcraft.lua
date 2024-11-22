---
-- @Liquipedia
-- wiki=commons
-- page=Module:Player/Display/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local DisplayUtil = require('Module:DisplayUtil')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent')
local PlayerDisplay = Lua.import('Module:Player/Display')
local StarcraftPlayerExt = Lua.import('Module:Player/Ext/Starcraft')

local TBD_ABBREVIATION = Abbreviation.make('TBD', 'To be determined (or to be decided)')

---Display components for players used in the starcraft and starcraft2 wikis.
---@class StarcraftPlayerDisplay: PlayerDisplay
local StarcraftPlayerDisplay = Table.copy(PlayerDisplay)

---@class StarcraftBlockPlayerProps: BlockPlayerProps
---@field player StarcraftStandardPlayer
---@field showFaction boolean?

---@class StarcraftInlinePlayerProps: InlinePlayerProps
---@field player StarcraftStandardPlayer
---@field showFaction boolean?

---@class InlinePlayerContainerProps: StarcraftInlinePlayerProps
---@field date string?
---@field savePageVar boolean?

---Displays a player as a block element.
---The width of the component is determined by its layout context, and not by the player name.
---@param props StarcraftBlockPlayerProps
---@return Html
function StarcraftPlayerDisplay.BlockPlayer(props)
	local player = props.player

	local zeroWidthSpace = '&#8203;'
	local nameNode = mw.html.create(props.dq and 's' or 'span')
		:wikitext(
			props.abbreviateTbd and Opponent.playerIsTbd(player) and TBD_ABBREVIATION
			or props.showLink ~= false and player.pageName
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

	local factionNode
	if props.showFaction ~= false and player.faction ~= Faction.defaultFaction then
		factionNode = mw.html.create('span'):addClass('race')
			:wikitext(Faction.Icon{faction = player.faction})
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
		:node(factionNode)
		:node(nameNode)
		:node(teamNode)
end

---Called from Template:Player and Template:Player2
---Only for non git usage!
---@param frame Frame
---@return string
function StarcraftPlayerDisplay.TemplatePlayer(frame)
	local args = require('Module:Arguments').getArgs(frame)

	local pageName
	local displayName
	if not args.noclean then
		pageName, displayName = StarcraftPlayerExt.extractFromLink(args[1] or '')
		local showLink = Logic.readBoolOrNil(args.link)
		if showLink == true then
			pageName = displayName
		elseif showLink == false then
			pageName = nil
		else
			pageName = args.link or pageName or displayName
		end
	else
		pageName = args.link
		displayName = args[1] or ''
	end

	local player = {
		displayName = displayName,
		flag = String.nilIfEmpty(args.flag),
		pageName = pageName,
		faction = String.nilIfEmpty(args.race) or String.nilIfEmpty(args.faction) or Faction.defaultFaction,
	}

	if not args.novar then
		StarcraftPlayerExt.saveToPageVars(player, {overwritePageVars = true})
	end

	local hiddenSortNode = args.hs
		and StarcraftPlayerDisplay.HiddenSort(player.displayName, player.flag, player.faction, args.hs)
		or ''
	local playerNode = StarcraftPlayerDisplay.InlinePlayer({
		dq = Logic.readBoolOrNil(args.dq),
		flip = Logic.readBoolOrNil(args.flip),
		player = player,
		showFaction = Logic.nilOr(Logic.readBoolOrNil(args.showRace), Logic.readBoolOrNil(args.showFaction), true),
	})
	return tostring(hiddenSortNode) .. tostring(playerNode)
end

---Called from Template:InlinePlayer
---Only for non git usage!
---@param frame Frame
---@return Html
function StarcraftPlayerDisplay.TemplateInlinePlayer(frame)
	local args = require('Module:Arguments').getArgs(frame)

	local player = {
		displayName = args[1],
		flag = args.flag,
		pageName = args.link,
		faction = Faction.read(args.race or args.faction),
	}
	return StarcraftPlayerDisplay.InlinePlayerContainer({
		date = args.date,
		dq = Logic.readBoolOrNil(args.dq),
		flip = Logic.readBoolOrNil(args.flip),
		player = player,
		savePageVar = not Logic.readBool(args.novar),
		showFlag = Logic.readBoolOrNil(args.showFlag),
		showLink = Logic.readBoolOrNil(args.showLink),
		showFaction = Logic.nilOr(Logic.readBoolOrNil(args.showRace), Logic.readBoolOrNil(args.showFaction)),
	})
end

--[[
Displays a player as an inline element. Useful for referencing players in
prose. This container will automatically look up the pageName, race/faction, and flag
of the player from page variables or LPDB, and save the results to page
variables.
]]
---@param props InlinePlayerContainerProps
---@return Html
function StarcraftPlayerDisplay.InlinePlayerContainer(props)
	StarcraftPlayerExt.syncPlayer(props.player, {
		date = props.date,
		savePageVar = props.savePageVar,
		overwritePageVars = true,
	})

	return StarcraftPlayerDisplay.InlinePlayer(props)
end

---Displays a player as an inline element. Useful for referencing players in prose.
---@param props StarcraftInlinePlayerProps
---@return Html
function StarcraftPlayerDisplay.InlinePlayer(props)
	local player = props.player

	local flag = props.showFlag ~= false and player.flag
		and PlayerDisplay.Flag(player.flag)
		or nil

	local faction = props.showFaction ~= false and player.faction ~= Faction.defaultFaction
		and Faction.Icon{faction = player.faction}
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
			.. (faction and '&nbsp;' .. faction or '')
			.. (flag and '&nbsp;' .. flag or '')
	else
		text = (flag and flag .. '&nbsp;' or '')
			.. (faction and faction .. '&nbsp;' or '')
			.. nameAndLink
	end

	return mw.html.create('span'):addClass('starcraft-inline-player')
		:addClass(props.flip and 'flipped' or nil)
		:wikitext(text)
end

---@param name string?
---@param flag string?
---@param faction string?
---@param field string?
---@return Html
function StarcraftPlayerDisplay.HiddenSort(name, flag, faction, field)
	local text
	if field == 'race' or field == 'faction' then
		text = faction
	elseif field == 'name' then
		text = name
	elseif field == 'flag' then
		text = flag
	else
		text = field
	end

	return mw.html.create('span')
		:css('display', 'none')
		:wikitext(text)
end

return StarcraftPlayerDisplay
