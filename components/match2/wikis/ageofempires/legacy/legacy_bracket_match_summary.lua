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
	local isValidMap = true
	local mapIndex = 1

	while isValidMap do
		local prefix = 'map' .. mapIndex

		--Template:MatchTeam
		local matchTeam = Json.parseIfTable(Table.extract(args, 'match' .. mapIndex)) or {}

		local mapArgs = {
			map = Table.extract(args, prefix) or Table.extract(matchTeam, 'map'),
			mode = Table.extract(args, prefix .. 'mode') or Table.extract(matchTeam, 'mapmode'),
			winner = Table.extract(args, prefix .. 'win') or Table.extract(matchTeam, 'win'),
			civs1 = Table.extract(args, prefix .. 'p1civ') or Table.extract(matchTeam, 't1civs'),
			civs2 = Table.extract(args, prefix .. 'p2civ') or Table.extract(matchTeam, 't2civs'),
			players1 = Table.extract(matchTeam, 't1players'),
			players2 = Table.extract(matchTeam, 't2players'),
			vod = Table.extract(args, 'vodgame' .. mapIndex),
			date = Table.extract(args, 'date' .. mapIndex) or Table.extract(matchTeam, 'date'),
		}
		if mapArgs.map then
			local mapInfo = Array.parseCommaSeparatedString(mapArgs.map, '|')
			mapArgs.map = mapInfo[1]
		end

		isValidMap = mapArgs.map ~= nil or mapArgs.winner
		args['map' .. mapIndex] = isValidMap and mapArgs or nil
		mapIndex = mapIndex + 1
	end

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
