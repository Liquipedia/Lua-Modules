---
-- @Liquipedia
-- wiki=chess
-- page=Module:Player/Display/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Abbreviation = require('Module:Abbreviation')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent')
local PlayerDisplay = Lua.import('Module:Player/Display')

local TBD_ABBREVIATION = Abbreviation.make('TBD', 'To be determined (or to be decided)')
local ZERO_WIDTH_SPACE = '&#8203;'

---@class ChessPlayerDisplay: PlayerDisplay
local CustomPlayerDisplay = Table.copy(PlayerDisplay)

---@class ChessBlockPlayerProps: BlockPlayerProps
---@field player ChessStandardPlayer

---@class ChessInlinePlayerProps: InlinePlayerProps
---@field player ChessStandardPlayer

---@param props ChessBlockPlayerProps
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
		flagNode = PlayerDisplay.Flag(player.flag)
	end

	local ratingNode = mw.html.create()
	if Logic.isNotEmpty(player.rating) then
		ratingNode:node(
			mw.html.create('small'):wikitext(player.rating)
		)
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
		:node(nameNode)
		:node(teamNode)
		:node(ratingNode)
end

---@param props ChessInlinePlayerProps
---@return Html
function CustomPlayerDisplay.InlinePlayer(props)
	local player = props.player

	local flag = props.showFlag ~= false and player.flag
		and PlayerDisplay.Flag(player.flag)
		or nil

	local rating = Logic.isNotEmpty(player.rating)
		and '<small>' .. player.rating .. '</small>'
		or nil

	local nameAndLink = props.showLink ~= false and player.pageName
		and '[[' .. player.pageName .. '|' .. player.displayName .. ']]'
		or player.displayName
	if props.dq then
		nameAndLink = '<s>' .. nameAndLink .. '</s>'
	end

	local text
	if props.flip then
		text = (rating and rating .. '&nbsp;' or '')
			.. nameAndLink
			.. (flag and '&nbsp;' .. flag or '')
	else
		text = (flag and flag .. '&nbsp;' or '')
			.. nameAndLink
			.. (rating and '&nbsp;' .. rating or '')
	end

	return mw.html.create('span'):addClass('starcraft-inline-player')
		:addClass(props.flip and 'flipped' or nil)
		:wikitext(text)
end

return CustomPlayerDisplay
