---
-- @Liquipedia
-- page=Module:LegacyBracketMatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Json = require('Module:Json')
local Table = require('Module:Table')

local DRAW = 'draw'
local SKIP = 'skip'

local LegacyBracketMatchSummary = {}

---@param args table
---@return table
function LegacyBracketMatchSummary._handleMaps(args)
	Array.mapIndexes(function(index)
		local prefix = 'map' .. index
		local map = args[prefix]
		local winner = Table.extract(args, prefix .. 'win')
		local score = Table.extract(args, prefix .. 'score')
		if Logic.isEmpty(map) and Logic.isEmpty(winner) then
			return false
		end

		if Logic.isNotEmpty(score) then
			local splitedScore = Array.parseCommaSeparatedString(score, '-')
			args[prefix .. 'score1'] = mw.text.decode(splitedScore[1])
			args[prefix .. 'score2'] = mw.text.decode(splitedScore[2])
		end

		args[prefix .. 'finished'] = (winner == SKIP and SKIP) or
			(not Logic.isEmpty(winner) and 'true') or 'false'

		if Logic.isNumeric(winner) or winner == DRAW then
			args[prefix .. 'winner'] = winner == DRAW and 0 or winner
		end
		return true
	end)

	return args
end

-- invoked by BracketMatchSummary
---@param frame Frame
---@return string
function LegacyBracketMatchSummary.convert(frame)
	local args = Arguments.getArgs(frame)
	args = LegacyBracketMatchSummary._handleMaps(args)

	return Json.stringify(args)
end

return LegacyBracketMatchSummary
