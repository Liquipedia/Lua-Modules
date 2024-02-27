---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Game = require('Module:Game')
local MapMode = require('Module:MapMode')
local Faction = require('Module:Faction')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = 'initial'}
local DRAW_LINE = Icon.makeIcon{iconName = 'draw', color = 'bright-sun-text', size = 'initial'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'

local LINKDATA = {
	mapdraft = {
		text = 'Map Draft',
		icon = 'File:Map Draft Icon.png'
	},
	civdraft = {
		text = 'Civ Draft',
		icon = 'File:Civ Draft Icon.png'
	}
}

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '285px'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryHeader
function CustomMatchSummary.createHeader(match)
	local header = MatchSummary.Header()

	return header
			:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
			:leftScore(header:createScore(match.opponents[1]))
			:rightScore(header:createScore(match.opponents[2]))
			:rightOpponent(header:createOpponent(match.opponents[2], 'right'))
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or (match.timestamp ~= DateExt.defaultTimestamp) then
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	if not CustomMatchSummary._isSolo(match) then return body end

	Array.forEach(match.games, function(game)
		if not game.map and not game.winner then return end
		local row = MatchSummary.Row()
				:addClass('brkts-popup-body-game')
				:css('font-size', '84%')
				:css('padding', '4px')
				:css('min-height', '24px')
		CustomMatchSummary._createGame(row, game, {game = match.game})
		body:addRow(row)
	end)

	return body
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	footer:addLinks(LINKDATA, match.links)

	if not Logic.readBool(match.extradata.headtohead) or not CustomMatchSummary._isSolo(match) then
		return footer
	end

	local player1, player2 = string.gsub(match.opponents[1].name, ' ', '_'),
			string.gsub(match.opponents[2].name, ' ', '_')
	return footer:addElement(
		'[[File:Match Info Stats.png|link=' ..
		tostring(mw.uri.fullUrl('Special:RunQuery/Match_history')) ..
		'?pfRunQueryFormName=Match+history&Head_to_head_query%5Bplayer%5D=' ..
		player1 ..
		'&Head_to_head_query%5Bopponent%5D=' .. player2 .. '&wpRunQuery=Run+query|Head-to-head statistics]]'
	)
end

---@param match MatchGroupUtilMatch
---@return boolean
function CustomMatchSummary._isSolo(match)
	if type(match.opponents[1]) ~= 'table' or type(match.opponents[2]) ~= 'table' then
		return false
	end
	return match.opponents[1].type == Opponent.solo and match.opponents[2].type == Opponent.solo
end

---@param game MatchGroupUtilGame
---@return string?
function CustomMatchSummary._getCivForPlayer(game, opponentIndex, playerIndex)
	if not game or not game.participants then
		return
	end
	local player = game.participants[opponentIndex .. '_' .. playerIndex]
	return (player or {}).civ
end

---@param row MatchSummaryRow
---@param game MatchGroupUtilGame
---@param props {game: string?}
function CustomMatchSummary._createGame(row, game, props)
	local normGame = Game.abbreviation{game = props.game}:lower()
	game.extradata = game.extradata or {}
	game.mapDisplayName = game.mapDisplayName or game.map
	if game.extradata.mapmode then
		game.mapDisplayName = game.mapDisplayName .. MapMode._get{game.extradata.mapmode}
	end
	row
			:addElement(CustomMatchSummary._createFactionIcon(CustomMatchSummary._getCivForPlayer(game, 1, 1), normGame))
			:addElement(CustomMatchSummary._createCheckMark(game.winner, 1))
			:addElement(mw.html.create('div')
				:addClass('brkts-popup-spaced'):css('flex-grow', '1')
				:wikitext(DisplayHelper.MapAndStatus(game))
			)
			:addElement(CustomMatchSummary._createCheckMark(game.winner, 2))
			:addElement(CustomMatchSummary._createFactionIcon(CustomMatchSummary._getCivForPlayer(game, 2, 1), normGame))
end

---@param civ string?
---@param game string
---@return Html
function CustomMatchSummary._createFactionIcon(civ, game)
	return mw.html.create('span')
		:addClass('draft faction')
		:wikitext(Faction.Icon{
			faction = civ or '',
			game = game,
			size = 64,
			showTitle = true,
			showLink = true,
		})
end

---@param winner integer|string
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._createCheckMark(winner, opponentIndex)
	return mw.html.create('div')
			:addClass('brkts-popup-spaced')
			:css('line-height', '17px')
			:css('margin-left', '1%')
			:css('margin-right', '1%')
			:wikitext(
				winner == opponentIndex and GREEN_CHECK
				or winner == 0 and DRAW_LINE or NO_CHECK
			)
end

return CustomMatchSummary
