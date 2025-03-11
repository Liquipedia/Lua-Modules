---
-- @Liquipedia
-- wiki=chess
-- page=Module:Player/Display/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local PlayerDisplay = Lua.import('Module:Player/Display')

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
	local ratingNode
	if Logic.isNotEmpty(player.rating) then
		ratingNode = mw.html.create('small'):wikitext(player.rating)
	end
	local display = PlayerDisplay.BlockPlayer(props)
	return display
		:addClass('starcraft-block-player')
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
