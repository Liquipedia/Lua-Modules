---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/TeamDisplay/Inline/Short
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TeamInlineWidget = Lua.import('Module:Widget/TeamDisplay/Inline')

---@class TeamShort: TeamInlineWidget
---@operator call(TeamInlineParameters): TeamShort
local TeamShort = Class.new(TeamInlineWidget)

---@return string
function TeamShort:getType()
	return 'short'
end

---@return string
function TeamShort:getDisplayName()
	return self.teamTemplate.shortname
end

return TeamShort
