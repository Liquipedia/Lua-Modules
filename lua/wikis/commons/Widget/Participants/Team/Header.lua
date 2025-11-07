-- @Liquipedia
-- page=Module:Widget/Participants/Team/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Widget = Lua.import('Module:Widget')
local ChevronToggle = Lua.import('Module:Widget/Participants/Team/ChevronToggle')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class ParticipantsTeamHeader: Widget
---@operator call(table): ParticipantsTeamHeader
local ParticipantsTeamHeader = Class.new(Widget)

function ParticipantsTeamHeader:render()
    local participant = self.props.participant
	local labelDiv = self:_renderLabel(participant)
	local variant = self.props.variant or 'compact'

	if variant == 'expanded' then
		return self:_renderExpanded(participant, labelDiv)
	end

	return self:_renderCompact(participant, labelDiv)
end

---@private
---@param participant TeamParticipantsEntity
---@param labelDiv Widget?
---@return Widget
function ParticipantsTeamHeader:_renderCompact(participant, labelDiv)
	return Div{
		classes = { 'team-participant-card-header' },
		children = WidgetUtil.collect(
			OpponentDisplay.BlockOpponent{
				opponent = participant.opponent,
				overflow = 'ellipsis',
				teamStyle = 'standard',
				additionalClasses = {'team-participant-card-header-opponent', 'team-participant-square-icon'},
			},
			labelDiv,
			ChevronToggle{}
		)
	}
end

---@private
---@param participant TeamParticipantsEntity
---@param labelDiv Widget?
---@return Widget
function ParticipantsTeamHeader:_renderExpanded(participant, labelDiv)
	local opponentDisplay = OpponentDisplay.BlockOpponent{
		opponent = participant.opponent,
		teamStyle = 'standard',
		additionalClasses = {'team-participant-card-header-opponent', 'team-participant-square-icon'},
	}

	return Div{
		classes = { 'team-participant-card-header', 'team-participant-card-header--expanded' },
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
---@param participant TeamParticipantsEntity
---@return Widget?
function ParticipantsTeamHeader:_renderLabel(participant)
	local labelText
	if String.isNotEmpty(participant.qualifierPage) or String.isNotEmpty(participant.qualifierUrl) then
		labelText = 'Qualifier'
	elseif String.isNotEmpty(participant.qualifierText) then
		labelText = 'Invited'
	end

	if not labelText then
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
