---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/CardsGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local TeamParticipantsRepository = Lua.import('Module:TeamParticipants/Repository')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
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
					local header = self:_renderHeader(participant)
					local content = self:_renderContent(participant)

					return Div{
						classes = { 'team-participant-card', 'is--collapsed' }, -- Hardcoded collapsed state until we implement the js
						attributes = {
							['data-component'] = 'team-participant-card',
							['data-team-participant-card-id'] = index
						},
						children = { header, content }
					}
				end),
			}
		},
	}
end

---@private
---@param participant TeamParticipantsEntity
---@return Widget
function ParticipantsTeamCard:_renderHeader(participant)
	local labelDiv = self:_renderLabel(participant)

	-- TODO: Implement the non-compact version
	return Div{
		classes = { 'team-participant-card-header' },
			attributes = {
				tabindex = "0",
				['data-component'] = "team-participant-card-collapsible-button"
		},
		children = WidgetUtil.collect(
			OpponentDisplay.BlockOpponent{
				opponent = participant.opponent,
				overflow = 'ellipsis',
				teamStyle = 'standard',
				additionalClasses = {'team-participant-card-header-opponent', 'team-participant-square-icon'},
			},
			labelDiv,
			Div{
				classes = { 'team-participant-card-header-icon' },
				children = { IconFa{iconName = 'collapse'}, }
			}
		)
	}
end

---@private
---@param participant TeamParticipantsEntity
---@return Widget?
function ParticipantsTeamCard:_renderLabel(participant)
	local labelText
	if String.isNotEmpty(participant.qualifierPage) or String.isNotEmpty(participant.qualifierUrl) then
		labelText = 'Qualifier'
	elseif String.isNotEmpty(participant.qualifierText) then
		labelText = 'Invited'
	end

	if labelText then
		return Div{
			classes = { 'team-participant-card-header-label' },
			children = {
				HtmlWidgets.Span{
					children = { labelText }
				}
			}
		}
	end
end

---@private
---@param participant TeamParticipantsEntity
---@return Widget
function ParticipantsTeamCard:_renderContent(participant)
	-- TODO: Implement qualifier box, roster functionality & notes
	return Div{
		classes = { 'team-participant-card-collapsible-content' },
		attributes = {
			['data-component'] = 'team-participant-card-content'
		},
		children = { participant.opponent.name } -- Team details & roster here
	}
end

return ParticipantsTeamCard
