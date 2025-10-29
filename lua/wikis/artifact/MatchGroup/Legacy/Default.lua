---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_NUMBER_OF_CHARACTERS = 5

---@class ArtifactMatchGroupLegacyDefault: MatchGroupLegacy
local MatchGroupLegacyDefault = Class.new(MatchGroupLegacy)

---@return table
function MatchGroupLegacyDefault:getMap()
	local map = {
		['$notEmpty$'] = 'g$1$p1score',
		map = 'g$1$',
		winner = 'g$1$win',
		vod = 'vodgame$1$',
		score1 = 'g$1$p1score',
		score2 = 'g$1$p2score',
	}

	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (oppIndex)
		local prefix = 'p' .. oppIndex
		Array.forEach(Array.range(1, MAX_NUMBER_OF_CHARACTERS), function (charIndex)
			map[prefix .. 'h' .. charIndex] = 'g$1$' .. prefix .. 'h' .. charIndex
		end)
		map[prefix .. 'd'] = prefix .. 'd$1$'
	end)

	return map
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.run(frame)
	return MatchGroupLegacyDefault(frame):build()
end

---@param frame Frame
---@return string
function MatchGroupLegacyDefault.runGenerate(frame)
	frame.args.template = frame.args[1]
	frame.args.templateOld = frame.args[2]
	frame.args.type = frame.args.type or 'team'

	return MatchGroupLegacyDefault(frame):generate()
end

return MatchGroupLegacyDefault
