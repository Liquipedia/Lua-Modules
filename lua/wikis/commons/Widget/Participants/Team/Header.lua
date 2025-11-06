---
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
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class ParticipantsTeamHeader: Widget
---@operator call(table): ParticipantsTeamHeader
local ParticipantsTeamHeader = Class.new(Widget)

function ParticipantsTeamHeader:render()
    local participant = self.props.participant
	local labelDiv = self:_renderLabel(participant)

	-- TODO: Implement the non-compact version
	return Div{
		classes = { 'team-participant-card-header' },
			attributes = {
				tabindex = '0',
				['data-component'] = 'team-participant-card-collapsible-button'
		},
		children = WidgetUtil.collect(
			OpponentDisplay.BlockOpponent{
				opponent = participant.opponent,
				overflow = 'ellipsis',
				teamStyle = 'standard',
				additionalClasses = {'team-participant-card-header-opponent', 'team-participant-square-icon'},
			},
			labelDiv,
			-- TODO: Implement toggle functionality
			Div{
				classes = { 'team-participant-card-header-icon' },
				children = IconFa{iconName = 'collapse'},
			}
		)
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
