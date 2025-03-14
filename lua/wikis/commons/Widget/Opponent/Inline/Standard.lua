---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Opponent/Inline/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TeamInlineWidget = Lua.import('Module:Widget/Opponent/Inline')

---@class TeamStandard: TeamInlineWidget
---@operator call(TeamInlineParameters): TeamStandard
local TeamStandard = Class.new(TeamInlineWidget)

---@return string
function TeamStandard:getType()
	return 'standard'
end

---@return string
function TeamStandard:getDisplayName()
	return self.teamTemplate.name
end

return TeamStandard
