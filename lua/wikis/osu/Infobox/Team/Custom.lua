---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local PlacementStats = Lua.import('Module:InfoboxPlacementStats')

local Team = Lua.import('Module:Infobox/Team')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class OsuInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return Widget
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@return Widget
function CustomTeam:createBottomContent()
	if not self.args.disbanded then
		return HtmlWidgets.Fragment{children = {
			PlacementStats.run{tiers = {'1', '2', '3', '4', '5'}}
		}}
	end
end

return CustomTeam
