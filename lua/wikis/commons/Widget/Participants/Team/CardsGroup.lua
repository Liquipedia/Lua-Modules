---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/CardsGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local TeamParticipantsRepository = Lua.import('Module:TeamParticipants/Repository')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class ParticipantsTeamCard: Widget
---@operator call(table): ParticipantsTeamCard
local ParticipantsTeamCard = Class.new(Widget)

---@return Widget?
function ParticipantsTeamCard:render()
	local participants = TeamParticipantsRepository.getAllByPageName(self.props.pageName)
	if not participants then
		return
	end

	return AnalyticsWidget{
		analyticsName = 'Team participants card',
		children = {
			Div{
				classes = { 'team-participant-cards' },
				children = Array.map(participants, function(participant)
					return Div{
						classes = { 'team-participant-card' },
						children = {
							Div{
								classes = { 'team-participant-card-header' },
								children = {
									OpponentDisplay.BlockOpponent{
										opponent = participant.opponent,
										overflow = 'ellipsis',
										teamStyle = 'standard',
										additionalClasses = {'team-participant-card-header-opponent', 'team-participant-square-icon'},
									},
									Div{
										classes = { 'team-participant-card-header-label' },
										children = {
											HtmlWidgets.Span{
												children = {
													participant.qualifierText and participant.qualifierText ~= '' and 'Qualified' or 'Invited'
												}
											}
										}
									},
									Div{
										classes = { 'team-participant-card-header-icon' },
										children = { IconFa{iconName = 'collapse'}, }
									}
								}
							}
						}
					}
				end),
			}
		},
	}
end

return ParticipantsTeamCard
