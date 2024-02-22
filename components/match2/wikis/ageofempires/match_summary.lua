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
local Faction = require('Module:Faction')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local VodLink = require('Module:VodLink')

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

function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '285px'})
end

function CustomMatchSummary.createHeader(match)
	local header = MatchSummary.Header()

	header:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
			:leftScore(header:createScore(match.opponents[1]))
			:rightScore(header:createScore(match.opponents[2]))
			:rightOpponent(header:createOpponent(match.opponents[2], 'right'))

	return header
end

function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or (match.timestamp ~= DateExt.defaultTimestamp) then
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	if CustomMatchSummary._isSolo(match) then
		for _, game in ipairs(match.games) do
			if game.map or game.winner then
				local row = MatchSummary.Row()
						:addClass('brkts-popup-body-game')
						:css('font-size', '84%')
						:css('padding', '4px')
						:css('min-height', '24px')
				CustomMatchSummary._createGame(row, game, {game = match.game})
				body:addRow(row)
			end
		end
	end

	return body
end

function CustomMatchSummary.createFooter(match)
	local footer = MatchSummary.Footer()

	if match.vod then
		footer:addElement(VodLink.display{
			vod = match.vod,
		})
	end

	-- Game Vods
	Array.forEach(match.games, function(game, index)
		if Logic.isEmpty(game.vod) then
			return
		end
		footer:addElement(VodLink.display{
			gamenum = index,
			vod = game.vod,
		})
	end)

	footer:addLinks(LINKDATA, match.links)

	if Logic.readBool(match.extradata.headtohead) and CustomMatchSummary._isSolo(match) then
		local player1, player2 = string.gsub(match.opponents[1].name, ' ', '_'),
				string.gsub(match.opponents[2].name, ' ', '_')
		footer:addElement(
			'[[File:Match Info Stats.png|link=' ..
			tostring(mw.uri.fullUrl('Special:RunQuery/Match_history')) ..
			'?pfRunQueryFormName=Match+history&Head_to_head_query%5Bplayer%5D=' ..
			player1 ..
			'&Head_to_head_query%5Bopponent%5D=' .. player2 .. '&wpRunQuery=Run+query|Head-to-head statistics]]'
		)
	end

	return footer
end

function CustomMatchSummary._isSolo(match)
	return match.opponents[1].type == Opponent.solo and	match.opponents[2].type == Opponent.solo
end

-- SoloOpponents only
function CustomMatchSummary._createGame(row, game, props)
	local normGame = Game.abbreviation{game = props.game}:lower()
	game.mapDisplayName = (game.extradata or {}).displayname
	row
			:addElement(CustomMatchSummary._createFactionIcon(game.participants['1_1'].civ, normGame))
			:addElement(CustomMatchSummary._createCheckMark(game.winner, 1))
			:addElement(mw.html.create('div')
				:addClass('brkts-popup-body-element-vertical-centered')
				:wikitext(DisplayHelper.MapAndStatus(game))
			)
			:addElement(CustomMatchSummary._createCheckMark(game.winner, 2))
			:addElement(CustomMatchSummary._createFactionIcon(game.participants['2_1'].civ, normGame))
end

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

function CustomMatchSummary._createCheckMark(winner, opponentIndex)
	return mw.html.create('div')
			:addClass('brkts-popup-body-element-vertical-centered')
			:css('line-height', '17px')
			:css('margin-left', '1%')
			:css('margin-right', '1%')
			:wikitext(
				winner == opponentIndex and GREEN_CHECK
				or winner == 0 and DRAW_LINE or NO_CHECK
			)
end

return CustomMatchSummary
