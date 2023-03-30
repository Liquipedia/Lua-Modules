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

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local ShortenBracket = {}

--- Builds the arguments to be passed to Bracket input processing
--- when shortening a bracket display
---@param args {bracketId: string, matchGroupId: string, skipRounds: integer, sourceId: string}
---@return table
function ShortenBracket.run(args)
	local newArgs = {
		'Bracket/' .. args.bracketId,
		id = args.matchGroupId,

		noDuplicateCheck = true,
		store = false,
		matchesAreProcessed = true,
	}

	local sourceIdLength = string.len(args.sourceId)
	local matches = MatchGroupUtil.fetchMatchRecords(args.sourceId)
	assert(Table.isNotEmpty(matches), 'No data found for "|matchGroupId=' .. args.sourceId .. '"')

	-- brackets always have the `R01-M001` match, hence checking for its existence ensures it is a bracket
	local firstMatchId = args.sourceId .. '_R01-M001'
	assert(Array.any(matches, function(match) return match.match2id == firstMatchId end),
		'The data found for "|matchGroupId=' .. args.sourceId .. '" seems to be no bracket')

	local hasFoundMatches
	for _, match in pairs(matches) do
		local matchId = string.sub(match.match2id, sourceIdLength + 2)
		local round = tonumber(string.sub(matchId, 2, 3))

		-- remove data that needs to be adjusted from input processing
		match.match2bracketdata = nil
		match.match2bracketid = nil
		match.match2id = nil

		-- keep reset/3rd place match, i.e. last round
		if not round then
			newArgs[matchId] = Json.stringify(match)

		-- valid match we want to keep
		elseif round > args.skipRounds then
			hasFoundMatches = true
			local newMatchId = 'R' .. (round - args.skipRounds) .. 'M' .. tonumber(string.sub(matchId, -3))
			newArgs[newMatchId] = Json.stringify(match)
		end
	end

	if not hasFoundMatches then
		error('The provided matchGroupId and skipRounds values leave an empty bracket')
	end

	return newArgs
end

return ShortenBracket
