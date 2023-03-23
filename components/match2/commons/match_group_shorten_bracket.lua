---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/ShortenBracket
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Json = require('Module:Json')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MatchGroup = Lua.import('Module:MatchGroup', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local ShortenBracket = {}

function ShortenBracket.run(args)
	args = args or {}

	local bracketId = string.gsub(args.bracketId or '', '^[bB]racket/', '')
	assert(String.isNotEmpty(bracketId), 'No bracketId specified')

	assert(args.matchGroupId, 'No matchGroupId specified')

	local sourceId = args.matchGroupId
	local matchGroupId = string.sub(sourceId, -10)

	local newArgs = {
		'Bracket/' .. bracketId,
		id = matchGroupId,

		noDuplicateCheck = true,
		store = false,
		matchesAreProcessed = true,
	}

	local skipRounds = tonumber(args.skipRounds)
	assert(skipRounds, 'No or invalid skipRounds specified')

	local sourceIdLength = string.len(sourceId)
	local matches = MatchGroupUtil.fetchMatchRecords(sourceId)
	assert(Table.isNotEmpty(matches), 'No data found for "|matchGroupId=' .. sourceId .. '"')
	local firstMatchId = sourceId .. '_R01-M001'
	assert(Array.any(matches, function(match) return match.match2id == firstMatchId end),
		'The data found for "|matchGroupId=' .. sourceId .. '" seems to be no bracket')

	for _, match in pairs(matches) do
		local matchId = string.sub(match.match2id, sourceIdLength + 2)
		local round = tonumber(string.sub(matchId, 2, 3))

		-- remove data that needs to be adjusted from input processing
		match.match2bracketdata = nil
		match.match2bracketid = nil
		match.match2id = nil

		-- reset/3rd place match, i.e. last round
		if not round then
			newArgs[matchId] = Json.stringify(match)

		-- valid match we want to keep
		elseif round > skipRounds then
			local newMatchId = 'R' .. (round - skipRounds) .. 'M' .. tonumber(string.sub(matchId, -3))
			newArgs[newMatchId] = Json.stringify(match)
		end
	end

	return MatchGroup.Bracket(newArgs)
end

return Class.export(ShortenBracket)
