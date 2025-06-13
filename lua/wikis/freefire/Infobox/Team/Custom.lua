---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PlacementStats = require('Module:InfoboxPlacementStats')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class FreefireInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'staff' then
		table.insert(widgets, 1, Cell{name = 'Founders', content = {args.founders}})
		table.insert(widgets, 2, Cell{name = 'CEO', content = {args.ceo}})
		table.insert(widgets, Cell{name = 'Analysts', content = {args.analysts}})
	end
	return widgets
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
