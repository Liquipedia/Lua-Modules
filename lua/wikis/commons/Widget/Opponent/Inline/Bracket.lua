---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Opponent/Inline/Bracket
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TeamInlineWidget = Lua.import('Module:Widget/Opponent/Inline')

---@class TeamBracket: TeamInlineWidget
---@operator call(TeamInlineParameters): TeamBracket
---@field props TeamInlineParameters
local TeamBracket = Class.new(TeamInlineWidget)

---@return string
function TeamBracket:getType()
	return 'bracket'
end

---@return string
function TeamBracket:getDisplayName()
	return self.teamTemplate.bracketname
end

return TeamBracket
