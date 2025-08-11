---
-- @Liquipedia
-- page=Module:Player/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DisplayUtil = Lua.import('Module:DisplayUtil')
local Logic = Lua.import('Module:Logic')
local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')

local Opponent = Lua.import('Module:Opponent')

local TBD = 'TBD'
local ZERO_WIDTH_SPACE = '&#8203;'

--Display components for players.
---@class PlayerDisplay
local PlayerDisplay = {}

---@class BlockPlayerProps
---@field flip boolean?
---@field player standardPlayer
---@field overflow OverflowModes?
---@field showFlag boolean?
---@field showLink boolean?
---@field showPlayerTeam boolean?
---@field dq boolean?
---@field note string|number|nil
---@field team string?
---@field showFaction boolean?
---@field game string?

---@class InlinePlayerProps
---@field flip boolean?
---@field player standardPlayer
---@field showFlag boolean?
---@field showLink boolean?
---@field dq boolean?
---@field showFaction boolean?
---@field game string?

--Displays a player as a block element. The width of the component is
--determined by its layout context, and not by the player name.
---@param props BlockPlayerProps
---@return Html
function PlayerDisplay.BlockPlayer(props)
	local player = props.player

	local nameNode = mw.html.create(props.dq and 's' or 'span'):addClass('name')

	if not Opponent.playerIsTbd(player) and props.showLink ~= false and Logic.isNotEmpty(player.pageName) then
		nameNode:wikitext('[[' .. player.pageName .. '|' .. player.displayName .. ']]')
	else
		nameNode:wikitext(Logic.emptyOr(player.displayName, ZERO_WIDTH_SPACE))
	end
	DisplayUtil.applyOverflowStyles(nameNode, props.overflow or 'ellipsis')

	local noteNode
	if props.note then
		noteNode = mw.html.create('sup'):addClass('note'):wikitext(props.note)
	end

	local flagNode
	if props.showFlag ~= false then
		flagNode = PlayerDisplay.Flag{flag = player.flag}
	end

	local factionNode
	if props.showFaction ~= false and Logic.isNotEmpty(player.faction) and player.faction ~= Faction.defaultFaction then
		factionNode = mw.html.create('span'):addClass('race')
			:wikitext(Faction.Icon{size = 'small', showLink = false, faction = player.faction, game = props.game})
	end

	local teamNode
	if props.showPlayerTeam and player.team and player.team:upper() ~= TBD then
		teamNode = mw.html.create('span')
			:wikitext('&nbsp;')
			:node(mw.ext.TeamTemplate.teampart(player.team))
	end

	return mw.html.create('div'):addClass('block-player')
		:addClass(props.flip and 'flipped' or nil)
		:addClass(props.showPlayerTeam and 'has-team' or nil)
		:node(flagNode)
		:node(factionNode)
		:node(nameNode)
		:node(noteNode)
		:node(teamNode)
end

---Displays a player as an inline element. Useful for referencing players in prose.
---@param props InlinePlayerProps
---@return Html
function PlayerDisplay.InlinePlayer(props)
	local player = props.player

	local flag = props.showFlag ~= false and player.flag
		and PlayerDisplay.Flag{flag = player.flag}
		or nil

	local faction = props.showFaction ~= false and Logic.isNotEmpty(player.faction)
		and player.faction ~= Faction.defaultFaction
		and Faction.Icon{size = 'small', showLink = false, faction = player.faction, game = props.game}
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
			.. (flag and ('&nbsp;' .. flag) or '')
	else
		text = (flag and (flag .. '&nbsp;') or '')
			.. (faction and faction .. '&nbsp;' or '')
			.. nameAndLink
	end

	return mw.html.create('span'):addClass('inline-player')
		:addClass(props.flip and 'flipped' or nil)
		:css('white-space', 'pre')
		:wikitext(text)
end

-- Note: Lua.import('Module:Flags').Icon automatically includes a span with class="flag"
---@param props {flag: string?}
---@return string
function PlayerDisplay.Flag(props)
	local flag = props.flag
	if not flag then
		flag = 'unknown'
	end
	return Flags.Icon{flag = flag, shouldLink = false}
end

return Class.export(PlayerDisplay, {exports = {
	'BlockPlayer',
	'InlinePlayer',
	'Flag',
}})
