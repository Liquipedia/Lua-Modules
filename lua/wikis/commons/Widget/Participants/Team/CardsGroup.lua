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
				children = Array.map(participants, function(participant, index)
					local boxId = self.props.pageName .. '-participant-' .. index

					-- TODO: Implement the non-compact version
					local header = Div{
						classes = { 'team-participant-card-header' },
						attributes = {
							tabindex = "0",
							['data-component'] = "team-participant-card-collapsible-button"
						},
						children = {
							-- TODO: Figure out flag rendering
							OpponentDisplay.BlockOpponent{
								opponent = participant.opponent,
								overflow = 'ellipsis',
								teamStyle = 'standard',
								additionalClasses = {'team-participant-card-header-opponent', 'team-participant-square-icon'},
							},
							-- TODO: Implement the label text logic properly and TBD coloring
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

					-- TODO: Implement qualifier box, roster functionality & notes
					local content = Div{
						classes = { 'team-participant-card-collapsible-content' },
						attributes = {
							['data-component'] = 'team-participant-card-content'
						},
						children = { 'content' } -- Team details & roster here
					}

					return Div{
						classes = { 'team-participant-card', 'is--collapsed' }, -- Hardcoded collapsed state
						attributes = {
							['data-component'] = 'team-participant-card',
							['data-team-participant-card-id'] = boxId
						},
						children = { header, content }
					}
				end),
			}
		},
	}
end

return ParticipantsTeamCard

