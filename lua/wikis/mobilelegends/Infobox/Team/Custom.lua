---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Team = Lua.import('Module:Infobox/Team')
local PlacementStats = Lua.import('Module:Infobox/Extension/PlacementStats')

---@class MobileLegendsInfoboxTeam: InfoboxTeam
---@operator call(Frame): MobileLegendsInfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return VNode
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@return VNode?
function CustomTeam:createBottomContent()
	return PlacementStats.run{}
end

return CustomTeam
