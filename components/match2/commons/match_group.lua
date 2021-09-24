---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local FeatureFlag = require('Module:FeatureFlag')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local MatchGroup = {}

-- Entry point used by Template:Bracket
function MatchGroup.bracket(frame)
	return MatchGroup.luaBracket(frame, Arguments.getArgs(frame))
end

function MatchGroup.luaBracket(frame, args)
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local MatchGroupBase = Lua.import('Module:MatchGroup/Base', {requireDevIfEnabled = true})
		return MatchGroupBase.luaBracket(frame, args)
	end)
end

-- Entry point used by Template:Matchlist
function MatchGroup.matchlist(frame)
	return MatchGroup.luaMatchlist(frame, Arguments.getArgs(frame))
end

function MatchGroup.luaMatchlist(frame, args)
	return FeatureFlag.with({dev = Logic.readBoolOrNil(args.dev)}, function()
		local MatchGroupBase = Lua.import('Module:MatchGroup/Base', {requireDevIfEnabled = true})
		return MatchGroupBase.luaMatchlist(frame, args)
	end)
end

return MatchGroup
