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
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local PlayerDisplay = require('Module:Player/Display')

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
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {
		width = CustomMatchSummary._determineWidth,
		teamStyle = 'bracket',
	})
end

---@param match MatchGroupUtilMatch
---@return string
function CustomMatchSummary._determineWidth(match)
	return CustomMatchSummary._isSolo(match) and '350px' or '550px'
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

	Array.forEach(match.games, function(game)
		if not game.map and not game.winner then return end
		local row = MatchSummary.Row()
				:addClass('brkts-popup-body-game')
				:css('font-size', '0.75rem')
				:css('padding', '4px')
				:css('min-height', '24px')

		CustomMatchSummary._createGame(row, game, {
			opponents = match.opponents,
			game = match.game,
			soloMode = CustomMatchSummary._isSolo(match)
		})
		body:addRow(row)
	end)

	-- casters
	body:addRow(MatchSummary.makeCastersRow(match.extradata.casters))

	return body
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	local addLinks = function(linkType)
		local currentLinkData = LINKDATA[linkType]
		if not currentLinkData then
			mw.log('Unknown link: ' .. linkType)
			return
		end
		for _, link in Table.iter.pairsByPrefix(match.links, linkType) do
			footer:addLink(link, currentLinkData.icon, currentLinkData.iconDark, currentLinkData.text)
		end
	end

	addLinks('mapdraft')
	addLinks('civdraft')

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
---@param paricipantId string
---@return {displayName: string?, pageName: string?, flag: string?, civ: string?}
function CustomMatchSummary._getPlayerData(game, paricipantId)
	if not game or not game.participants then
		return {}
	end
	return game.participants[paricipantId] or {}
end

---@param row MatchSummaryRow
---@param game MatchGroupUtilGame
---@param props {game: string?, soloMode: boolean, opponents: standardOpponent[]}
function CustomMatchSummary._createGame(row, game, props)
	local normGame = Game.abbreviation{game = props.game}:lower()
	game.extradata = game.extradata or {}
	game.mapDisplayName = game.mapDisplayName or game.map

	if game.extradata.mapmode then
		game.mapDisplayName = game.mapDisplayName .. MapMode._get{game.extradata.mapmode}
	end

	local faction1, faction2

	if props.soloMode then
		faction1 = CustomMatchSummary._createFactionIcon(CustomMatchSummary._getPlayerData(game, '1_1').civ, normGame)
		faction2 = CustomMatchSummary._createFactionIcon(CustomMatchSummary._getPlayerData(game, '2_1').civ, normGame)
	else
		local function createParticipant(participantId, flipped)
			local player = CustomMatchSummary._getPlayerData(game, participantId)
			local playerNode = PlayerDisplay.BlockPlayer{player = player, flip = flipped}
			local factionNode = CustomMatchSummary._createFactionIcon(player.civ, normGame)
			return mw.html.create('div'):css('display', 'flex'):css('align-self', flipped and 'end' or 'start')
				:node(flipped and playerNode or factionNode)
				:wikitext('&nbsp;')
				:node(flipped and factionNode or playerNode)
		end
		local function createOpponentDisplay(opponentId)
			local display = mw.html.create('div'):css('display', 'flex'):css('flex-direction', 'column'):css('width', '35%')
			for participantId in Table.iter.pairsByPrefix(game.participants, opponentId .. '_') do
				display:node(createParticipant(participantId, opponentId == 1))
			end
			return display
		end

		faction1 = createOpponentDisplay(1)
		faction2 = createOpponentDisplay(2)
	end

	row
			:css('flex-wrap', 'nowrap')
			:addElement(faction1)
			:addElement(CustomMatchSummary._createCheckMark(game.winner, 1, props.soloMode))
			:addElement(mw.html.create('div')
				:addClass('brkts-popup-spaced'):css('flex-grow', '1')
				:wikitext(DisplayHelper.MapAndStatus(game))
			)
			:addElement(CustomMatchSummary._createCheckMark(game.winner, 2, props.soloMode))
			:addElement(faction2)
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
---@param soloMode boolean
---@return Html
function CustomMatchSummary._createCheckMark(winner, opponentIndex, soloMode)
	return mw.html.create('div')
			:addClass('brkts-popup-spaced')
			:css('line-height', '17px')
			:css('margin-left', (opponentIndex == 1 and soloMode) and '10%' or '1%')
			:css('margin-right', (opponentIndex == 2 and soloMode) and '10%' or '1%')
			:wikitext(
				winner == opponentIndex and GREEN_CHECK
				or winner == 0 and DRAW_LINE or NO_CHECK
			)
end

return CustomMatchSummary
