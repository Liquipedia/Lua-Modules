---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:LegacyBracketMatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Json = require('Module:Json')
local Table = require('Module:Table')

local LegacyBracketMatchSummary = {}

---@param args table
---@return table
function LegacyBracketMatchSummary._handleMaps(args)
	Array.mapIndexes(function(index)
		local prefix = 'map' .. index

		--Template:MatchTeam
		if args['match' .. index] then
			local match = Json.parse(Table.extract(args, 'match' .. index)) --[[@as table]]
			Table.mergeInto(args,
					Table.map(match, function(subKey, value)
						return prefix .. subKey, value
					end)
			)
			args[prefix] = Table.extract(args, prefix .. 'map')
			args[prefix .. 'mode'] = Table.extract(args, prefix .. 'mapmode')
			args['date' .. index] = Table.extract(args, prefix .. 'date')
		end

		if args[prefix] then
			local mapInfo = Array.parseCommaSeparatedString(args[prefix], '|')
			args[prefix] = mapInfo[1]
		end

		return args[prefix] or args[prefix .. 'win']
	end)

	return args
end

-- invoked by BracketMatchSummary
---@param frame Frame
---@return string
function LegacyBracketMatchSummary.convert(frame)
	local args = Arguments.getArgs(frame)
	args = LegacyBracketMatchSummary._handleMaps(args)
	args['civdraft'] = Table.extract(args, 'draft')

	return Json.stringify(args)
end

return LegacyBracketMatchSummary
