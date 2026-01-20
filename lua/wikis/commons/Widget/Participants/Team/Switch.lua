---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Switch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Switch = Lua.import('Module:Widget/Switch')

---@class ParticipantsTeamCardsGroupSwitch: Widget
---@operator call(): ParticipantsTeamCardsGroupSwitch
local ParticipantsTeamCardsGroupSwitch = Class.new(Widget)

---@return Widget?
function ParticipantsTeamCardsGroupSwitch:render()
	return Div{
		classes = { 'team-participant__switches' },
		children = {
			AnalyticsWidget{
				analyticsName = 'ParticipantsShowRostersSwitch',
				analyticsProperties = {
					['track-value-as'] = 'participants show rosters',
				},
				children = Switch{
					label = 'Show rosters',
					switchGroup = 'team-cards-show-rosters',
					defaultActive = false,
					collapsibleSelector = '.team-participant-card',
				},
			},
			AnalyticsWidget{
				analyticsName = 'ParticipantsCompactSwitch',
				analyticsProperties = {
					['track-value-as'] = 'participants compact',
				},
				children = Switch{
					label = 'Compact view',
					switchGroup = 'team-cards-compact',
					defaultActive = true,
				},
			}
		}
	}
end

return ParticipantsTeamCardsGroupSwitch
