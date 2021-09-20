---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchGroupBase = require('Module:MatchGroup/Base')

local MatchGroup = {}

-- Entry point used by Template:Bracket
function MatchGroup.bracket(frame)
	return MatchGroupBase.bracket(frame)
end

function MatchGroup.luaBracket(frame, args)
	return MatchGroupBase.luaBracket(frame, args)
end

-- Entry point used by Template:Matchlist
function MatchGroup.matchlist(frame)
	return MatchGroupBase.matchlist(frame)
end

function MatchGroup.luaMatchlist(frame, args)
	return MatchGroupBase.luaMatchlist(frame, args)
end

return MatchGroup
