---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Widget = Lua.import('Module:Widget')
local ChevronToggle = Lua.import('Module:Widget/Participants/Team/ChevronToggle')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class ParticipantsTeamHeader: Widget
---@operator call(table): ParticipantsTeamHeader
local ParticipantsTeamHeader = Class.new(Widget)

---@return Widget
function ParticipantsTeamHeader:render()
	local participant = self.props.participant
	local labelDiv = self:_renderLabel(participant)

	local opponentDisplay = OpponentDisplay.BlockOpponent{
		opponent = participant.opponent,
		teamStyle = 'standard',
		additionalClasses = {'team-participant-card-header-opponent', 'team-participant-card-square-icon'}
	}

	return Div{
		classes = { 'team-participant-card-header' },
		children = {
			Div{
				classes = {'team-participant-card-header__main'},
				children = WidgetUtil.collect(
					opponentDisplay,
					labelDiv
				)
			},
			ChevronToggle{}
		}
	}
end

---@private
---@param participant TeamParticipant
---@return Widget?
function ParticipantsTeamHeader:_renderLabel(participant)
	local labelText
	local qualificationData = participant.qualification
	if not qualificationData then
		return
	end

	if qualificationData.method == 'qual' then
		labelText = 'Qualifier'
	elseif qualificationData.method == 'invite' then
		labelText = 'Invited'
	else
		return
	end

	return Div{
		classes = { 'team-participant-card-header-label' },
		children = {
			HtmlWidgets.Span{
				children = { labelText }
			}
		}
	}
end

return ParticipantsTeamHeader
