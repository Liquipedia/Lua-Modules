---
-- @Liquipedia
-- wiki=clashofclans
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Date = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px'})
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	return MatchSummary.addVodsToFooter(match, footer)
end

function CustomMatchSummary.createHeader(match)
	local header = MatchSummary.Header()

	local opponentLeft = match.opponents[1]
	local opponentRight = match.opponents[2]

	-- for Bo1 overwritte opponents scores with game score for matchsummary header display
	if match.bestof == 1 and match.games and match.games[1] and
		not match.opponents[1].placement2 and not match.opponents[2].placement2 then

		opponentLeft = Table.merge(match.opponents[1], {score = (match.games[1].scores or {})[1] or 0})
		opponentRight = Table.merge(match.opponents[2], {score = (match.games[1].scores or {})[2] or 0})
	end


	header:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
		:leftScore(header:createScore(opponentLeft))
		:rightScore(header:createScore(opponentRight))
		:rightOpponent(header:createOpponent(match.opponents[2], 'right'))

	return header
end

function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= Date.defaultTimestamp then
		-- dateIsExact means we have both date and time. Show countdown
		-- if match is not default date, we have a date, so display the date
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	-- Iterate over games
	for gameIndex, game in ipairs(match.games) do
		if Table.isNotEmpty(game.scores) then
			body:addRow(CustomMatchSummary._createMapRow(game, gameIndex))
		end
	end

	-- Add Match MVP(s)
	if (match.extradata or {}).mvp then
		local mvpData = match.extradata.mvp
		if not Table.isEmpty(mvpData) and mvpData.players then
			local mvp = MatchSummary.Mvp()
			for _, player in ipairs(mvpData.players) do
				mvp:addPlayer(player)
			end
			mvp:setPoints(mvpData.points)

			body:addRow(mvp)
		end

	end

	return body
end

function CustomMatchSummary._gameScore(game, opponentIndex)
	local score = game.scores[opponentIndex] or ''
	return mw.html.create('div')
		:css('width', '16px')
		:wikitext(score)
end

function CustomMatchSummary._percentage(game, opponentIndex)
	local percentage = game.extradata.percentages[opponentIndex]

	if not percentage then return end

	return mw.html.create('div')
		:css('font-size', '80%')
		:css('width', '48px')
		:wikitext(Abbreviation.make('(' .. percentage .. '%)', 'Average Damage Percentage'))
end

function CustomMatchSummary._time(game, opponentIndex)
	local time = game.extradata.times[opponentIndex]

	if not time then return end

	return mw.html.create('div')
		:css('font-size', '80%')
		:css('width', '40px')
		:wikitext(Abbreviation.make('(' .. os.date('%M:%S', time) .. ')', 'Total Time'))
end

function CustomMatchSummary._createMapRow(game, gameIndex)
	local row = MatchSummary.Row()

	-- Add Header
	if Logic.isNotEmpty(game.header) then
		local mapHeader = mw.html.create('div')
			:wikitext(game.header)
			:css('font-weight','bold')
			:css('font-size','85%')
			:css('margin','auto')
		row:addElement(mapHeader)
		row:addElement(MatchSummary.Break():create())
	end

	local centerNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:wikitext('Game ' .. gameIndex)

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local leftNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 1))
		:node(CustomMatchSummary._gameScore(game, 1))
		:node(CustomMatchSummary._percentage(game, 1))
		:node(CustomMatchSummary._time(game, 1))

	local rightNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._time(game, 2))
		:node(CustomMatchSummary._percentage(game, 2))
		:node(CustomMatchSummary._gameScore(game, 2))
		:node(CustomMatchSummary._createCheckMarkOrCross(game.winner == 2))

	row:addElement(leftNode)
		:addElement(centerNode)
		:addElement(rightNode)

	row:addClass('brkts-popup-body-game')
		:css('text-align', 'center')
		:css('overflow', 'hidden')

	-- Add Comment
	if Logic.isNotEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		local comment = mw.html.create('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		row:addElement(comment)
	end

	return row
end

function CustomMatchSummary._createCheckMarkOrCross(showIcon)
	local container = mw.html.create('div')
	container:addClass('brkts-popup-spaced'):css('line-height', '27px')

	if showIcon then
		container:node(GREEN_CHECK)
	else
		container:node(NO_CHECK)
	end

	return container
end

return CustomMatchSummary
