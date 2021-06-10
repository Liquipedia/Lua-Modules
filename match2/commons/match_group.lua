local MatchGroupBase = require('Module:MatchGroup/Base')

local MatchGroup = {}

function MatchGroup.bracket(frame)
	return MatchGroupBase.bracket(frame)
end

function MatchGroup.luaBracket(frame, args)
	return MatchGroupBase.luaBracket(frame, args)
end

function MatchGroup.matchlist(frame)
	return MatchGroupBase.matchlist(frame)
end

function MatchGroup.luaMatchlist(frame, args)
	return MatchGroupBase.luaMatchlist(frame, args)
end

return MatchGroup
