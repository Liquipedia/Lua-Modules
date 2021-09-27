---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MatchGroupDisplay = Lua.import('Module:MatchGroup/Display', {requireDevIfEnabled = true})

local MatchGroup = {}

-- Entry point used by Template:Bracket
-- Deprecated
function MatchGroup.bracket(frame)
	return MatchGroupDisplay.TemplateBracket(frame)
end

-- Deprecated
function MatchGroup.luaBracket(_, args)
	return MatchGroupDisplay.TemplateBracket(args)
end

-- Entry point used by Template:Matchlist
-- Deprecated
function MatchGroup.matchlist(frame)
	return MatchGroupDisplay.TemplateMatchlist(frame)
end

-- Deprecated
function MatchGroup.luaMatchlist(_, args)
	return MatchGroupDisplay.TemplateMatchlist(args)
end

return MatchGroup
