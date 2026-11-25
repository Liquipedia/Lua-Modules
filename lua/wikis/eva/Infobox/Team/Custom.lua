---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Team = Lua.import('Module:Infobox/Team')
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

---@class EVAInfoboxTeam: InfoboxTeam
---@operator call(Frame): EVAInfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return VNode
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@return VNode?
function CustomTeam:createBottomContent()
	return UpcomingTournaments.team{name = self.teamTemplate.templatename}
end

return CustomTeam
