---
-- @Liquipedia
-- page=Module:Player/Display/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Abbreviation = require('Module:Abbreviation')
local FnUtil = require('Module:FnUtil')
local Characters = require('Module:Characters')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent')
local PlayerDisplay = Lua.import('Module:Player/Display')

local TBD_ABBREVIATION = Abbreviation.make{text = 'TBD', title = 'To be determined (or to be decided)'}
local ZERO_WIDTH_SPACE = '&#8203;'

---@class FightersPlayerDisplay: PlayerDisplay
local CustomPlayerDisplay = Table.copy(PlayerDisplay)

---@class FightersBlockPlayerProps: BlockPlayerProps
---@field player FightersStandardPlayer
---@field oneLine boolean?

---@class FightersInlinePlayerProps: InlinePlayerProps
---@field player FightersStandardPlayer

---@param props FightersBlockPlayerProps
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

	local characterNode = mw.html.create()
	if player.chars then
		local chars = Array.map(player.chars, function (character)
			return mw.html.create('span'):addClass('race'):wikitext(CustomPlayerDisplay.character(player.game, character))
		end)
		Array.forEach(Array.interleave(chars, ' '), function (character)
			characterNode:node(character)
		end)
	end

	local teamNode
	if props.showPlayerTeam and player.team and player.team:lower() ~= 'tbd' then
		teamNode = mw.html.create('span')
			:wikitext('&nbsp;')
			:node(mw.ext.TeamTemplate.teampart(player.team))
	end

	if props.oneLine then
		return mw.html.create('div'):addClass('block-player starcraft-block-player')
			:addClass(props.flip and 'flipped' or nil)
			:addClass(props.showPlayerTeam and 'has-team' or nil)
			:node(flagNode)
			:node(characterNode)
			:node(nameNode)
			:node(teamNode)
	end

	return mw.html.create()
		:node(
			mw.html.create('div'):addClass('block-player starcraft-block-player')
			:addClass(props.flip and 'flipped' or nil)
			:addClass(props.showPlayerTeam and 'has-team' or nil)
			:node(flagNode)
			:node(nameNode)
			:node(teamNode)
		)
		:node(characterNode)
end

---@param props FightersInlinePlayerProps
---@return Html
function CustomPlayerDisplay.InlinePlayer(props)
	local player = props.player

	local flag = props.showFlag ~= false and player.flag
		and PlayerDisplay.Flag{flag = player.flag}
		or nil

	local faction = player.chars
		and table.concat(Array.map(player.chars, FnUtil.curry(CustomPlayerDisplay.character, player.game)))
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

function CustomPlayerDisplay.character(game, character)
	return Characters.GetIconAndName{character, game = game}
end

return CustomPlayerDisplay
