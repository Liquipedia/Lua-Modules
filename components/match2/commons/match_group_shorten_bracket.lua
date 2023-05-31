---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/ShortenBracket
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupCoordinates = Lua.import('Module:MatchGroup/Coordinates', {requireDevIfEnabled = true})
local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local ShortenBracket = {}

local FIRST_MATCH_KEY = 'R01-M001'

local _bracket_datas_by_id

--- Fetches and adjusts matches so they can be displayed in the shortened format
---@param props {bracketId: string, shortTemplate: string, args: table}
---@return table
function ShortenBracket.fetchAndAdjustMatches(props)
	local shortTemplate = 'Bracket/' .. string.gsub(props.shortTemplate, '^[bB]racket/', '')
	local matches = MatchGroupUtil.fetchMatchRecords(props.bracketId)
	_bracket_datas_by_id = MatchGroupInput._fetchBracketDatas(shortTemplate, props.bracketId)

	assert(matches[1].match2bracketdata.type == 'bracket',
		'The data found for id "' .. props.bracketId .. '" is not a bracket')

	return ShortenBracket._processMatches(
		matches,
		string.len(props.bracketId),
		ShortenBracket._getSkipRoundValue(shortTemplate, props.bracketId, matches[1]),
		props.bracketId
	)
end

function ShortenBracket._getSkipRoundValue(shortTemplate, bracketId, firstMatch)
	local newRoundCount = _bracket_datas_by_id[FIRST_MATCH_KEY].coordinates.roundCount
	local oldRoundCount = firstMatch.match2bracketdata.coordinates.roundCount

	return oldRoundCount - newRoundCount
end

function ShortenBracket._processMatches(matches, idLength, skipRounds, bracketId)
	local newMatches = {}

	for _, match in ipairs(matches) do
		local matchId = string.sub(match.match2id, idLength + 2)
		local round = tonumber(string.sub(matchId, 2, 3))


		-- keep reset/3rd place match, i.e. last round
		if not round then
			table.insert(newMatches, match)

		-- valid match we want to keep
		elseif round > skipRounds then
			local newMatchId = 'R' .. string.format('%02d', round - skipRounds) .. '-M' .. string.sub(matchId, -3)

			assert(_bracket_datas_by_id[newMatchId], 'bracket <--> short bracket missmatch: ' .. newMatchId)

			match.match2id = string.sub(match.match2id, 1, idLength + 1) .. newMatchId

			-- nil some stuff before merge
			match.match2bracketdata.loweredges = nil

			match.match2bracketdata = Table.merge(match.match2bracketdata, _bracket_datas_by_id[newMatchId], {
				header = match.match2bracketdata.header
			})

			-- have to do this after the merge so that correct `match.match2bracketdata.lowerMatchIds` is available
			match.match2bracketdata.loweredges = ShortenBracket._calculateLowerEdges(match)

			table.insert(newMatches, match)
		end
	end

	assert(newMatches[1], 'The provided id and shortTemplate values leave an empty bracket')

	Variables.varDefine('match2bracket_' .. bracketId, Json.stringify(newMatches))

	return MatchGroupUtil.fetchMatchGroup(bracketId).matches
end

function ShortenBracket._calculateLowerEdges(match)
	return Array.map(
		MatchGroupUtil.autoAssignLowerEdges(#match.match2bracketdata.lowerMatchIds, #match.match2opponents),
		MatchGroupUtil.indexTableToRecord
	)
end

return ShortenBracket
