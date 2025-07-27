---
-- @Liquipedia
-- page=Module:LegacyBracketMatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

local MAX_NUM_MAPS = 20

local LegacyBracketMatchSummary = {}

---@param frame Frame
---@return string
function LegacyBracketMatchSummary.run(frame)
	local args = Arguments.getArgs(frame)

	---@param prefix string
	---@return boolean
	local mapIsNotEmpty = function(prefix)
		return Logic.isNotEmpty(args[prefix]) or
			Logic.isNotEmpty(args[prefix .. 'type']) or
			Logic.isNotEmpty(args[prefix .. 'score'])
	end

	Array.forEach(Array.range(1, MAX_NUM_MAPS), function(mapIndex)
		local prefix = 'map' .. mapIndex
		-- make sure map is processed in `Module:MatchGroup/Legacy/Default` if any valid input for map is given
		args[prefix .. 'win'] = args[prefix .. 'win'] or mapIsNotEmpty(prefix) and 'skip' or nil

		-- convert the map score input into a format that `Module:MatchGroup/Legacy/Default` can process
		local scorePrefix = prefix .. 'score'
		local scoreInput = Table.extract(args, scorePrefix)
		if Logic.isEmpty(scoreInput) then return end
		local scores = Array.parseCommaSeparatedString(scoreInput, '-')
		args[scorePrefix .. 1] = scores[1]
		args[scorePrefix .. 2] = scores[2]
	end)

	return Json.stringify(args)
end

return LegacyBracketMatchSummary
