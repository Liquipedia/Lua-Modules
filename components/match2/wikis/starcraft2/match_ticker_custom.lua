---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:MatchTicker/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require("Module:Lua")
local Logic = require("Module:Logic")

local CustomMatches = Lua.import('Module:Matches/match2', {requireDevIfEnabled = true})

local _SCORE_STATUS = 'S'
local _STATUS_RECENT = 'recent'
local _STATUS_UPCOMING = 'upcoming'
local _DISPLAY_MODE_DEFAULT = 'default'

-- override functions
function CustomMatches.requireOpponentModules()
	return Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true}),
		Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})
end

function CustomMatches.tbdIdentifier()
	return 'definitions'
end

function CustomMatches.adjustConditions(conditions, args, status, displayMode)
	if Logic.readBool(args.featured) then
		table.insert(conditions, '[[extradata_featured::true]]')
	end
	return conditions
end

function CustomMatches.versus(opponentLeft, opponentRight, winner, bestof, finished, status)
	local versus

	if status == _STATUS_UPCOMING then
		versus = 'vs.'
	else
		local leftScore, leftScore2 = CustomMatches.getOpponentScore(opponentLeft)
		local rightScore, rightScore2 = CustomMatches.getOpponentScore(opponentRight)

		versus = CustomMatches.displayOpponentScore(leftScore, finished and winner == 1)
			.. ':'
			.. CustomMatches.displayOpponentScore(rightScore, finished and winner == 2)

		local hasScore2 = (leftScore2 + rightScore2) > 0

		if hasScore2 then
			local lowerScoreDisplay = mw.html.create('div')
				:css('font-size', '80%')
				:css('padding-bottom', '1px')
				:wikitext('(' .. versus .. ')')

			local upperScore = CustomMatches.displayOpponentScore(leftScore2, winner == 1)
				.. ':'
				.. CustomMatches.displayOpponentScore(rightScore, winner == 2)

			local upperScoreDisplay = mw.html.create('div')
				:css('line-height', '1.1')
				:wikitext(upperScore)

			versus = mw.html.create('div')
				:node(upperScoreDisplay)
				:node(lowerScoreDisplay)
		end
	end

	bestof = tonumber(bestof or '')
	if status ~= _STATUS_RECENT and bestof and not hasScore2 then
		local bestofDisplay = mw.html.create('abbr')
			:attr('title', 'Best of ' .. bestof)
			:wikitext('Bo' .. bestof)

		local upperVersus = mw.html.create('div')
			:css('line-height', '1.1')
			:node(versus)

		local lowerVersus = mw.html.create('div')
			:css('font-size', '80%')
			:css('padding-bottom', '1px')
			:wikitext('(')
			:node(bestofDisplay)
			:wikitext(')')

		versus = mw.html.create('div')
			:node(upperVersus)
			:node(lowerVersus)
	end

	return versus
end

function CustomMatches.getOpponentScore(opponent)
	local score
	if opponent.status == _SCORE_STATUS then
		score = tonumber(opponent.score)
		if score == -1 then
			score = 0
		end
	else
		score = opponent.status or ''
	end

	local score2 = 0
	if type(opponent.extradata) == 'table' then
		score2 = tonumber(opponent.extradata.score2 or '') or 0
	end

	return score, score2
end

function CustomMatches.addUpperRowClass(upperRow, status, displayMode, data)
	if
		status ~= _STATUS_RECENT and
		displayMode == _DISPLAY_MODE_DEFAULT and
		Logic.readBool((data.extradata or {}).featured)
	then
		upperRow:addClass('sc2premier-highlighted')
	end

	return upperRow
end

return Class.export(CustomMatches)
