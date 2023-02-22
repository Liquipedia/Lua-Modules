---
-- @Liquipedia
-- wiki=fifa
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})
local PlayerDisplay = Lua.import('Module:Player/Display', {requireDevIfEnabled = true})

local GREEN_CHECK = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>'
local DRAW_LINE = '<i class="fas fa-minus bright-sun-text" style="width: 14px; text-align: center" ></i>'
local NO_CHECK = '[[File:NoCheck.png|link=]]'

local CustomMatchSummary = {}

function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = MatchSummary():init()
	matchSummary.root:css('flex-wrap', 'unset')

	matchSummary:header(CustomMatchSummary._createHeader(match))
				:body(CustomMatchSummary._createBody(match))

	if match.comment then
		local comment = MatchSummary.Comment():content(match.comment)
		matchSummary:comment(comment)
	end

	local vods = {}
	for index, game in ipairs(match.games) do
		if not Logic.isEmpty(game.vod) then
			vods[index] = game.vod
		end
	end

	if not Table.isEmpty(vods) or String.isNotEmpty(match.vod) then
		local footer = MatchSummary.Footer()

		if match.vod then
			footer:addElement(VodLink.display{
				vod = match.vod,
			})
		end

		-- Game Vods
		for index, vod in pairs(vods) do
			footer:addElement(VodLink.display{
				gamenum = index,
				vod = vod,
			})
		end

		matchSummary:footer(footer)
	end

	return matchSummary:create()
end

function CustomMatchSummary._createHeader(match)
	local header = MatchSummary.Header()

	header:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
		:leftScore(header:createScore(match.opponents[1]))
		:rightScore(header:createScore(match.opponents[2]))
		:rightOpponent(header:createOpponent(match.opponents[2], 'right'))

	return header
end

function CustomMatchSummary._createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or (match.timestamp ~= DateExt.epochZero) then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not epoch=0, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	for _, game in ipairs(match.games) do
		local row = MatchSummary.Row()
			:addClass('brkts-popup-body-game')
			:css('font-size', '84%')
			:css('padding', '4px')
			:css('min-height', '32px')

		if Logic.readBool((match.extradata or {}).hassubmatches) then
			CustomMatchSummary._createSubMatch(row, game, match)
		else
			CustomMatchSummary._createGame(row, game)
		end

		-- Add Comment
		if not Logic.isEmpty(game.comment) then
			row
				:addElement(MatchSummary.Break():create())
				:addElement(mw.html.create('div')
					:wikitext(game.comment)
					:css('margin', 'auto')
				)
		end

		body:addRow(row)
	end

	return body
end

function CustomMatchSummary._createGame(row, game)
	row
		:addElement(CustomMatchSummary._createCheckMark(game.winner, 1))
		:addElement(CustomMatchSummary._score(game.scores[1] or 0))
		:addElement(mw.html.create('div')
			:addClass('brkts-popup-body-element-vertical-centered')
			:wikitext(game.map)
		)
		:addElement(CustomMatchSummary._score(game.scores[2] or 0))
		:addElement(CustomMatchSummary._createCheckMark(game.winner, 2))
end

function CustomMatchSummary._createSubMatch(row, game, match)
	local players = CustomMatchSummary._extractPlayersFromGame(game, match)

	row
		-- player left side
		:addElement(CustomMatchSummary._player(players[1], 1, game.winner))
		-- score
		:addElement(CustomMatchSummary._score(game.scores[1] or 0))
		-- penalty score
		:addElement(CustomMatchSummary._score(CustomMatchSummary._subMatchPenaltyScore(game, 1)))
		:addElement(mw.html.create('div')
			:addClass('brkts-popup-body-element-vertical-centered')
			:wikitext(' vs ')
		)
		-- penalty score
		:addElement(CustomMatchSummary._score(CustomMatchSummary._subMatchPenaltyScore(game, 2)))
		-- score
		:addElement(CustomMatchSummary._score(game.scores[2] or 0))
		-- player right side
		:addElement(CustomMatchSummary._player(players[2], 2, game.winner))
end

function CustomMatchSummary._extractPlayersFromGame(game, match)
	local players = {{}, {}}

	for participantKey, participant in Table.iter.spairs(game.participants or {}) do
		participantKey = mw.text.split(participantKey, '_')
		local opponentIndex = tonumber(participantKey[1])
		local match2playerIndex = tonumber(participantKey[2])

		local player = match.opponents[opponentIndex].players[match2playerIndex]

		if not player then
			player = {
				displayName = participant.displayname,
				pageName = participant.name,
			}
		end

		players[opponentIndex] = player
	end

	return players
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

function CustomMatchSummary._score(score)
	if not score then return end

	return mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(score)
end

function CustomMatchSummary._subMatchPenaltyScore(game, opponentIndex)
	local scores = (game.extradata or {}).penaltyscores

	if not scores then return NO_CHECK end

	return Abbreviation.make(
		'(' .. (scores[opponentIndex] or 0) .. ')',
		'Penalty shoot-out'
	)
end

function CustomMatchSummary._player(player, opponentIndex, winner)
	local flip = opponentIndex == 1

	return mw.html.create('div')
		:addClass(winner == opponentIndex and 'bg-win' or winner == 0 and 'bg-draw' or nil)
		:css('align-items', 'center')
		:css('border-radius', flip and '0 12px 12px 0' or '12px 0 0 12px')
		:css('padding', '2px 8px')
		:css('text-align', flip and 'right' or 'left')
		:css('width', '35%')
		:node(PlayerDisplay.BlockPlayer{
			player = player,
			flip = flip,
		})
end

return CustomMatchSummary
