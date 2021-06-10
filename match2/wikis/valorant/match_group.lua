local MatchGroup = require('Module:MatchGroup/Base')
local Arguments = require('Module:Arguments')
local Table = require('Module:Table')

local CustomMatchGroup = {}

local _matches = {}
local _bracketId = ''

function CustomMatchGroup.matchlist(frame)
	local args = Arguments.getArgs(frame)
	_bracketId = CustomMatchGroup._getBracketData(args)
	_matches = CustomMatchGroup._getMatches(_bracketId)

	return MatchGroup.luaMatchlist(frame, args, CustomMatchGroup._matchBuilder)
end

function CustomMatchGroup.bracket(frame)
	local args = Arguments.getArgs(frame)
	_bracketId = CustomMatchGroup._getBracketData(args)
	_matches = CustomMatchGroup._getMatches(_bracketId)

	return MatchGroup.luaBracket(frame, args, CustomMatchGroup._matchBuilder)
end

function CustomMatchGroup._getBracketData(args)
	local bracketId = args["id"]
	if bracketId == nil or bracketId == "" then
		error("argument 'id' is empty")
	end

	-- make sure bracket id is valid
	validateBracketID(bracketId)

	return bracketId
end

function CustomMatchGroup._getMatches(bracketId)
	return mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = '[[namespace::130]] AND [[match2bracketid::MATCH_'.. bracketId .. ']]'
	})
end

function CustomMatchGroup._matchBuilder(frame, match, matchId)
	local matchData = CustomMatchGroup._findMatchData(_matches, matchId)

	if matchData == nil then
		return match
	end

	local opponents = matchData['match2opponents']
	match['opponent1'] = opponents[1]
	match['opponent2'] = opponents[2]

	local match2games = matchData['match2games']

	for i = 0, Table.size(match2games) do
		match['map' .. (i + 1)] = match2games[i]
	end

	return match

end

function CustomMatchGroup._findMatchData(matches, matchId)
	if matchId == nil then
		return nil
	end

	local parsedMatchId = CustomMatchGroup._convertMatchIdentifier(matchId)
	local formattedMatchId = ''

	if parsedMatchId == nil then
		formattedMatchId = 'ID_' .. matchId
	else
		formattedMatchId = 'ID_' .. _bracketId .. '_' .. parsedMatchId
	end

	for _, match in pairs(matches) do
		if match['pagename'] == formattedMatchId then
			return match
		end
	end

	return nil
end

function CustomMatchGroup._convertMatchIdentifier(identifier)
	local roundPrefix, roundNumber, matchPrefix, matchNumber = string.match(identifier, "(R)([0-9]*)(M)([0-9]*)")
	
	if roundPrefix == nil then
		-- This is a matchlist
		return nil
	end

	return roundPrefix .. string.format("%02d", roundNumber) .. "-" .. matchPrefix .. string.format("%03d", matchNumber)
end

return CustomMatchGroup
