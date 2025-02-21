---
-- @Liquipedia
-- wiki=freefire
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PlacementStats = require('Module:InfoboxPlacementStats')
local Template = require('Module:Template')

local Team = Lua.import('Module:Infobox/Team')

---@class FreefireInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@return string
function CustomTeam:createBottomContent()
	return tostring(PlacementStats.run{
		tiers = {'1', '2', '3', '4'},
		participant = self.name,
	}) .. Template.expandTemplate(
		mw.getCurrentFrame(),
		'Upcoming and ongoing tournaments of',
		{team = self.name}
	)
end

return CustomTeam
