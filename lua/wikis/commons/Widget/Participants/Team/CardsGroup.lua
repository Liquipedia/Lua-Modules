---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/CardsGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local ParticipantsTeamCard = Lua.import('Module:Widget/Participants/Team/Card')
local Switch = Lua.import('Module:Widget/Switch')

local globalVars = PageVariableNamespace()

---@class ParticipantsTeamCardsGroup: Widget
---@operator call(table): ParticipantsTeamCardsGroup
local ParticipantsTeamCardsGroup = Class.new(Widget)

---@return Widget?
function ParticipantsTeamCardsGroup:render()
	local participants = self.props.participants
	if not participants then
		return
	end

	local showSwitches = not globalVars:get('teamParticipantControlsRendered')

	return Div{
		classes = { 'team-participant' },
		children = {
			showSwitches and Div{
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
			} or nil,
			AnalyticsWidget{
				analyticsName = 'Team participants card',
				children = Div{
					classes = { 'team-participant__grid' },
					children = Array.map(participants, function(participant)
						return ParticipantsTeamCard{
							participant = participant,
						}
					end),
				}
			}
		}
	}
end

return ParticipantsTeamCardsGroup
