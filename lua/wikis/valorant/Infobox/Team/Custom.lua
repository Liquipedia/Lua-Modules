---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Injector = Lua.import('Module:Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')

local Widgets = Lua.import('Module:Widget/All')
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
			children = {args.igl}
		})
	elseif id == 'custom' then
		return {
			Cell{name = '[[Affiliate_Partnerships|Affiliate]]', children = {
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
