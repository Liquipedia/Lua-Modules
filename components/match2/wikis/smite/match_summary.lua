---
-- @Liquipedia
-- wiki=smite
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Abbreviation = require('Module:Abbreviation')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local MAX_NUM_BANS = 5
local NUM_GODS_PICK = 5
local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'

local LINK_DATA = {
	smiteesports = {
		icon = 'File:SMITE default lightmode.png',
		iconDark = 'File:SMITE default darkmode.png',
		text = 'Smite Esports Match Page'
	},
	stats = {icon = 'File:Match_Info_Stats.png', text = 'Match Statistics'},
}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.defaultTimestamp then
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate each map
	for gameIndex, game in ipairs(match.games) do
		local rowDisplay = CustomMatchSummary._createGame(game, gameIndex, match.date)
		body:addRow(rowDisplay)
	end

	-- casters
	body:addRow(MatchSummary.makeCastersRow(match.extradata.casters))

	-- Add the Character Bans
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)
	body.root:node(MatchSummaryWidgets.CharacterBanTable{
		bans = characterBansData,
		date = match.date,
	})

	return body
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@param date string
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game, gameIndex, date)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	-- TODO: Change to use participant data
	local characterData = {
		MatchSummary.buildCharacterList(extradata, 'team1god', NUM_GODS_PICK),
		MatchSummary.buildCharacterList(extradata, 'team2god', NUM_GODS_PICK),
	}

	row:addClass('brkts-popup-body-game')
		:css('font-size', '80%')
		:css('padding', '4px')
		:css('min-height', '32px')

	row:addElement(MatchSummaryWidgets.Characters{
		flipped = false,
		characters = characterData[1],
		date = date,
		bg = 'brkts-popup-side-color-' .. (extradata.team1side or ''),
	})
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(Abbreviation.make(
			Logic.isEmpty(game.length) and ('Game ' .. gameIndex) or game.length,
			Logic.isEmpty(game.length) and ('Game ' .. gameIndex .. ' picks') or 'Match Length'
			))
		)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner == 2))
	row:addElement(MatchSummaryWidgets.Characters{
		flipped = true,
		characters = characterData[2],
		date = date,
		bg = 'brkts-popup-side-color-' .. (extradata.team2side or ''),
	})

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = mw.html.create('div')
		comment:wikitext(game.comment):css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

---@param isWinner boolean?
---@return Html
function CustomMatchSummary._createCheckMark(isWinner)
	local container = mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:css('line-height', '17px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')

	if Logic.readBool(isWinner) then
		container:node(GREEN_CHECK)
	else
		container:node(NO_CHECK)
	end

	return container
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)
	return footer:addLinks(LINK_DATA, match.links)
end

return CustomMatchSummary
