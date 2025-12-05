---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/CardsGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local Button = Lua.import('Module:Widget/Basic/Button')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local ParticipantsTeamCard = Lua.import('Module:Widget/Participants/Team/Card')
local Switch = Lua.import('Module:Widget/Switch')

---@class ParticipantsTeamCardsGroupProps
---@field participants TeamParticipant[]?

---@class ParticipantsTeamCardsGroup: Widget
---@operator call(ParticipantsTeamCardsGroupProps): ParticipantsTeamCardsGroup
---@field props ParticipantsTeamCardsGroupProps
local ParticipantsTeamCardsGroup = Class.new(Widget)

---@return Widget?
function ParticipantsTeamCardsGroup:render()
	local participants = self.props.participants
	if not participants then
		return
	end

	return Div{
		classes = { 'team-participant' },
		children = {
			Div{
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
					},
					Button{
						linktype = 'external',
						link = tostring(mw.uri.fullUrl('Special:RunQuery/Tournament player information', {
							pfRunQueryFormName = 'Tournament player information',
							['TPI[page]'] = mw.title.getCurrentTitle().text,
							wpRunQuery = 'Run query'
						})),
						size = 'sm',
						variant = 'secondary',
						title = 'Click for additional player information',
						children = Array.interleave({
							IconFa{iconName = 'link'},
							'Player',
							'Info'
						}, '&nbsp;')
					}
				}
			},
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
