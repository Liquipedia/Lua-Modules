---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Injector = Lua.import('Module:Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local UpcomingTournaments = Lua.import('Module:Widget/Infobox/UpcomingTournaments')

---@class ValorantInfoboxTeam: InfoboxTeam
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
		table.insert(widgets, Cell{
			name = 'In-Game Leader',
			content = {args.igl}
		})
	elseif id == 'custom' then
		return {
			Cell{name = '[[Affiliate_Partnerships|Affiliate]]', content = {
				args.affiliate and OpponentDisplay.InlineTeamContainer{template = args.affiliate, displayType = 'standard'} or nil}}
		}
	end
	return widgets
end

---@return string?
function CustomTeam:createBottomContent()
	if not self.args.disbanded then
		return UpcomingTournaments{name = self.pagename}
	end
end

return CustomTeam
