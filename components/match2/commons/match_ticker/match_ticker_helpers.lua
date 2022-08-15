---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker/Helpers
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- Holds helper functions for the MatchTicker modules

local Table = require('Module:Table')
local String = require('Module:StringUtils')

local HelperFunctions = {}

local _SCORE_STATUS = 'S'
local _BYE_OPPONENT = 'bye'

local _lastTournament
local _lastMatchWasTbd

-- overridable values
HelperFunctions.tbdIdentifier = 'tbd'
HelperFunctions.featuredClass = 'valvepremier-highlighted'

function HelperFunctions.getOpponentScore(opponent, isWinner, hasScore2)
	local score
	if opponent.status == _SCORE_STATUS then
		score = tonumber(opponent.score)
		if score == -1 then
			score = 0
		end
	else
		score = opponent.status or ''
	end
	if isWinner then
		score = '<b>' .. score .. '</b>'
	end

	local score2 = 0
	if type(opponent.extradata) == 'table' then
		score2 = tonumber(opponent.extradata.score2 or 0) or 0
	end
	if score2 > 0 then
		hasScore2 = true
		if isWinner then
			score = '<b>' .. score .. '</b>'
		end
	end

	return score, score2, hasScore2
end

function HelperFunctions.opponentIsTbdOrEmpty(opponent)
	local firstPlayer = (opponent.players or {})[1] or {}

	local listToCheck = {
		string.lower(firstPlayer.pageName or opponent.name or ''),
		string.lower(firstPlayer.displayName or ''),
		string.lower(opponent.template or ''),
	}

	return Table.includes(listToCheck, HelperFunctions.tbdIdentifier)
		or Table.all(listToCheck, function(_, value) return String.isEmpty(value) end)
end

function HelperFunctions.isByeOpponent(opponent)
	if not opponent then
		return true
	end
	local name = string.lower(opponent.name or '')
	local template = string.lower(opponent.template or '')

	return name == _BYE_OPPONENT
		or template == _BYE_OPPONENT
end

function HelperFunctions.checkForTbdMatches(opponent1, opponent2, currentTournament)
	local isTbdMatch  = HelperFunctions.opponentIsTbdOrEmpty(opponent1) and HelperFunctions.opponentIsTbdOrEmpty(opponent2)

	if isTbdMatch and _lastTournament == currentTournament then
		_lastMatchWasTbd = true
		isTbdMatch = _lastMatchWasTbd
	else
		isTbdMatch = false
		_lastMatchWasTbd = false
	end

	_lastTournament = currentTournament

	return isTbdMatch
end

function HelperFunctions.isFeatured(matchData)
	return String.isNotEmpty(matchData.publishertier)
end

return HelperFunctions
