---
-- @Liquipedia
-- wiki=commons
-- page=Module:RecentMatches/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require("Module:Lua")

local StarcraftRecentMatches = Lua.import('Module:RecentMatches', {requireDevIfEnabled = true})

local _CURRENT_DATE_STAMP = mw.getContentLanguage():formatDate('c')
local _SCORE_STATUS = 'S'

-- override functions
function StarcraftRecentMatches.requireOpponentModules()
	return Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true}),
		Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})
end

function StarcraftRecentMatches.buildConditions(args)
	local featured = args.featured == 'true'

	local conditions = '[[dateexact::1]] AND [[finished::1]] AND [[date::<' .. _CURRENT_DATE_STAMP .. ']]'
	if featured then
		conditions = conditions .. ' AND [[extradata_featured::true]]'
	end

	return conditions
end

function StarcraftRecentMatches.scoreDisplay(opponentLeft, opponentRight, winner)
	local leftScore, leftScore2 = StarcraftRecentMatches.getOpponentScore(opponentLeft)
	local rightScore, rightScore2 = StarcraftRecentMatches.getOpponentScore(opponentRight)

	local scoreDisplay = StarcraftRecentMatches._displayOpponentScore(leftScore, winner == 1)
		.. ':'
		.. StarcraftRecentMatches._displayOpponentScore(rightScore, winner == 2)

	local hasScore2 = (leftScore2 + rightScore2) > 0

	if hasScore2 then
		local lowerScoreDisplay = mw.html.create('div')
			:css('font-size', '80%')
			:css('padding-bottom', '1px')
			:wikitext('(' .. scoreDisplay .. ')')

		local upperScore = StarcraftRecentMatches._displayOpponentScore(leftScore2, winner == 1)
			.. ':'
			.. StarcraftRecentMatches._displayOpponentScore(rightScore, winner == 2)

		local upperScoreDisplay = mw.html.create('div')
			:css('line-height', '1.1')
			:wikitext(upperScore)

		scoreDisplay = mw.html.create('div')
			:node(upperScoreDisplay)
			:node(lowerScoreDisplay)
	end

	return scoreDisplay
end

function StarcraftRecentMatches.getOpponentScore(opponent)
	local score
	if opponent.status == _SCORE_STATUS then
		score = tonumber(opponent.score)
		if score == -1 then
			score = 0
		end
	else
		score = opponent.status or ''
	end

	--custom for sc2:
	local score2 = 0
	if type(opponent.extradata) == 'table' then
		score2 = tonumber(opponent.extradata.score2 or '') or 0
	end

	return score, score2
end

return Class.export(StarcraftRecentMatches)
