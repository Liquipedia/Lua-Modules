---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/TeamDisplay/Inline/Icon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TeamInlineWidget = Lua.import('Module:Widget/TeamDisplay/Inline')

---@class TeamIcon: TeamInlineWidget
---@operator call(TeamInlineParameters): TeamIcon
local TeamIcon = Class.new(TeamInlineWidget)

---@return string
function TeamIcon:getType()
	return 'icon'
end

---@return string
function TeamIcon:getDisplayName()
	return ''
end

return TeamIcon
