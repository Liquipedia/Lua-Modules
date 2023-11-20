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
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})

local OpponentLibrary = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibrary.OpponentDisplay

local GREEN_CHECK = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>'
local DRAW_LINE = '<i class="fas fa-minus bright-sun-text" style="width: 14px; text-align: center" ></i>'
local NO_CHECK = '[[File:NoCheck.png|link=]]'

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
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

---@param row MatchSummaryRow
---@param game MatchGroupUtilGame
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

---@param row MatchSummaryRow
---@param game MatchGroupUtilGame
---@param match MatchGroupUtilMatch
function CustomMatchSummary._createSubMatch(row, game, match)
	local players = CustomMatchSummary._extractPlayersFromGame(game, match)

	row
		-- player left side
		:addElement(CustomMatchSummary._players(players[1], 1, game.winner))
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
		:addElement(CustomMatchSummary._players(players[2], 2, game.winner))
end

---@param game MatchGroupUtilGame
---@param match MatchGroupUtilMatch
---@return table[][]
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

		table.insert(players[opponentIndex], player)
	end

	return players
end

---@param winner integer
---@param opponentIndex integer
---@return Html
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

---@param score number|string|nil
---@return Html?
function CustomMatchSummary._score(score)
	if not score then return end

	return mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(score)
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return string
function CustomMatchSummary._subMatchPenaltyScore(game, opponentIndex)
	local scores = (game.extradata or {}).penaltyscores

	if not scores then return NO_CHECK end

	return Abbreviation.make(
		'(' .. (scores[opponentIndex] or 0) .. ')',
		'Penalty shoot-out'
	)--[[@as string]]
end

---@param players table[]
---@param opponentIndex integer
---@param winner integer
---@return Html
function CustomMatchSummary._players(players, opponentIndex, winner)
	local flip = opponentIndex == 1

	return mw.html.create('div')
		:addClass(winner == opponentIndex and 'bg-win' or winner == 0 and 'bg-draw' or nil)
		:css('align-items', 'center')
		:css('border-radius', flip and '0 12px 12px 0' or '12px 0 0 12px')
		:css('padding', '2px 8px')
		:css('text-align', flip and 'right' or 'left')
		:css('width', '35%')
		:node(OpponentDisplay.BlockPlayers{
			opponent = {players = players},
			overflow = 'ellipsis',
			showLink = true,
		})
end

return CustomMatchSummary
