---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/ShortenBracket
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Json = require('Module:Json')
local Table = require('Module:Table')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local ShortenBracket = {}

local FIRST_MATCH_EXTENDED_KEY = 'R01-M001'
local FIRST_MATCH_KEY = 'R1M1'

--- Builds the arguments to be passed to Bracket input processing
--- when shortening a bracket display
---@param props {bracketId: string, shortTemplate: string, args: table}
---@return table
function ShortenBracket.buildArgs(props)
	local shortTemplate = 'Bracket/' .. string.gsub(props.shortTemplate, '^[bB]racket/', '')
	local bracketId = props.bracketId

	local newArgs = Table.merge(props.args, {
		shortTemplate,
		id = bracketId:sub(-10),

		noDuplicateCheck = true,
		store = false,
		matchesAreProcessed = true,
	})

	local matches = MatchGroupUtil.fetchMatchRecords(bracketId)

	assert(Table.isNotEmpty(matches), 'No data found for id "' .. bracketId .. '"')
	assert(matches[1].match2bracketdata.type == 'bracket',
		'The data found for id "' .. bracketId .. '" seems to be no bracket')

	ShortenBracket._processMatchesToArgs(
		newArgs,
		matches,
		string.len(bracketId),
		ShortenBracket._getSkipRoundValue(shortTemplate, bracketId, matches[1])
	)

	assert(newArgs[FIRST_MATCH_KEY], 'The provided id and shortTemplate values leave an empty bracket')

	return newArgs
end

function ShortenBracket._getSkipRoundValue(shortTemplate, bracketId, firstMatch)
	local bracketDatasById = MatchGroupInput._fetchBracketDatas(shortTemplate, bracketId)
	local newRoundCount = bracketDatasById[FIRST_MATCH_EXTENDED_KEY].coordinates.roundCount
	local oldRoundCount = firstMatch.match2bracketdata.coordinates.roundCount

	return oldRoundCount - newRoundCount
end

function ShortenBracket._processMatchesToArgs(newArgs, matches, idLength, skipRounds)
	for _, match in pairs(matches) do
		local matchId = string.sub(match.match2id, idLength + 2)
		local round = tonumber(string.sub(matchId, 2, 3))

		match.bracketdata = {header = match.match2bracketdata.header}

		-- remove data that needs to be adjusted from input processing
		match.match2bracketdata = nil
		match.match2bracketid = nil
		match.match2id = nil

		-- keep reset/3rd place match, i.e. last round
		if not round then
			newArgs[matchId] = Json.stringify(match)

		-- valid match we want to keep
		elseif round > skipRounds then
			hasFoundMatches = true
			local newMatchId = 'R' .. (round - skipRounds) .. 'M' .. tonumber(string.sub(matchId, -3))
			newArgs[newMatchId] = Json.stringify(match)
		end
	end
end

return ShortenBracket
