---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/ParticipantControls
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Switch = Lua.import('Module:Widget/Switch')

local globalVars = PageVariableNamespace()

---@class ParticipantsTeamParticipantControls: Widget
---@operator call(table): ParticipantsTeamParticipantControls
local ParticipantsTeamParticipantControls = Class.new(Widget)

---@return Widget?
function ParticipantsTeamParticipantControls:render()
	local title = mw.title.getCurrentTitle().fullText
	mw.log('ParticipantControls DEBUG: rendering on page:', title)
	globalVars:set('teamParticipantControlsRendered', 'true')
	mw.log('ParticipantControls DEBUG: set teamParticipantControlsRendered = true')
	mw.log('ParticipantControls DEBUG: verifying:', globalVars:get('teamParticipantControlsRendered'))

	return Div{
		classes = { 'team-participant__controls' },
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

return ParticipantsTeamParticipantControls
