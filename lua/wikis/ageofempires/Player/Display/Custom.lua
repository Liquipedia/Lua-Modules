---
-- @Liquipedia
-- page=Module:Player/Display/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local DisplayUtil = require('Module:DisplayUtil')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent')
local PlayerDisplay = Lua.import('Module:Player/Display')

local TBD_ABBREVIATION = Abbreviation.make{text = 'TBD', title = 'To be determined (or to be decided)'}
local ZERO_WIDTH_SPACE = '&#8203;'

---@class AoEStandardPlayer:standardPlayer
---@field faction string?

---@class AoEBlockPlayerProps: BlockPlayerProps
---@field player AoEStandardPlayer
---@field game string?
---@field showFaction boolean?

---@class AoEInlinePlayerProps: InlinePlayerProps
---@field player AoEStandardPlayer
---@field game string?
---@field showFaction boolean?

---@class AoEPlayerDisplay: PlayerDisplay
local CustomPlayerDisplay = Table.copy(PlayerDisplay)

---@param props AoEBlockPlayerProps
---@return Html
function CustomPlayerDisplay.BlockPlayer(props)
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
		flagNode = PlayerDisplay.Flag{flag = player.flag}
	end

	local factionNode
	if props.showFaction ~= false and player.faction ~= Faction.defaultFaction then
		factionNode = mw.html.create('span'):addClass('race')
			:wikitext(CustomPlayerDisplay.Faction(player.faction, props.game))
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

---@param props AoEInlinePlayerProps
---@return Html
function CustomPlayerDisplay.InlinePlayer(props)
	local player = props.player

	local flag = props.showFlag ~= false and player.flag
		and PlayerDisplay.Flag{flag = player.flag}
		or nil

	local faction = props.showFaction ~= false and player.faction ~= Faction.defaultFaction
		and CustomPlayerDisplay.Faction(player.faction)
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

function CustomPlayerDisplay.Faction(faction, game)
	return Faction.Icon{size = 'small', showLink = false, faction = faction, game = game}
end

return CustomPlayerDisplay
