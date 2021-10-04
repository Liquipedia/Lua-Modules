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
	return MatchGroupDisplay.TemplateBracket(frame) .. MatchGroupDisplay.deprecatedCategory
end

-- Deprecated
function MatchGroup.luaBracket(_, args)
	return MatchGroupDisplay.TemplateBracket(args) .. MatchGroupDisplay.deprecatedCategory
end

-- Entry point used by Template:Matchlist
-- Deprecated
function MatchGroup.matchlist(frame)
	return MatchGroupDisplay.TemplateMatchlist(frame) .. MatchGroupDisplay.deprecatedCategory
end

-- Deprecated
function MatchGroup.luaMatchlist(_, args)
	return MatchGroupDisplay.TemplateMatchlist(args) .. MatchGroupDisplay.deprecatedCategory
end

return MatchGroup
