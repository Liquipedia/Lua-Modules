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
-- local LeagueIcon = Lua.import('Module:LeagueIcon')
-- local Tournament = Lua.import('Module:Tournament')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class ParticipantsTeamCardParameters
---@field pageName string
---@field variant 'compact'|'expanded'|nil

---@class ParticipantsTeamCard: Widget
---@operator call(ParticipantsTeamCardParameters): ParticipantsTeamCard
---@field props ParticipantsTeamCardParameters
local ParticipantsTeamCard = Class.new(Widget)
ParticipantsTeamCard.defaultProps = {
	variant = 'compact',
}

---@return Widget?
function ParticipantsTeamCard:render()
	local participants = TeamParticipantsRepository.getAllByPageName(self.props.pageName)
	if not participants then
		return
	end

	return AnalyticsWidget{
		analyticsName = 'Team participants card',
		children = Div{
			classes = { 'team-participant-cards' },
			children = Array.map(participants, function(participant, index)
				local header = self:_renderHeader(participant)
				local qualifierBox = self:_renderQualifierBox(participant)

				local content = self:_renderContent(participant, qualifierBox)

				local cardChildren = { header }

				if self.props.variant == 'expanded' then
					table.insert(cardChildren, qualifierBox)
				end

				table.insert(cardChildren, content)

				return Div{
					classes = { 'team-participant-card', 'is--collapsed' }, -- Hardcoded collapsed state until we implement the js
					attributes = {
						['data-component'] = 'team-participant-card',
						['data-team-participant-card-id'] = index
					},
					children = WidgetUtil.collect(cardChildren)
				}
			end),
		}
	}
end

---@private
---@param participant TeamParticipantsEntity
---@return Widget
function ParticipantsTeamCard:_renderHeader(participant)
	local labelDiv = self:_renderLabel(participant)
	local variant = self.props.variant
	local headerClasses = { 'team-participant-card-header' }

	-- TODO: Should be stylistically same as compact on <= 1023 viewports
	if variant == 'expanded' then
		table.insert(headerClasses, 'team-participant-card-header--expanded')
	end

	return Div{
		classes = headerClasses,
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
---@return Widget?
function ParticipantsTeamCard:_renderQualifierBox(participant)
	local qualifierPage = participant.qualifierPage

	if not String.isNotEmpty(qualifierPage) then
		return
	end

	return Div{
		classes = { 'team-participant-card-qualifier' },
		children = {
			-- TODO: Render the qualifier tournament icon
			-- LeagueIcon.display{
			-- 	icon = Tournament.icon(qualifierPage),
			-- 	iconDark = Tournament.darkIcon(qualifierPage),
			-- 	series = Tournament.series(qualifierPage),
			-- 	link = qualifierPage,
			-- 	options = {noTemplate = true},
			-- },
			Div{
				classes = { 'team-participant-card-qualifier-details' },
				children = Link{
					link = qualifierPage,
					children = participant.qualifierText
				}
			}
		}
	}
end

---@private
---@param participant TeamParticipantsEntity
---@param qualifierBox Widget?
---@return Widget
function ParticipantsTeamCard:_renderContent(participant, qualifierBox)
	local contentChildren = {}

	if self.props.variant == 'compact' then
		table.insert(contentChildren, qualifierBox)
	end

	-- TODO: Roster functionality & notes
	table.insert(contentChildren, participant.opponent.name) -- Placeholder until proper content is added

	return Div{
		classes = { 'team-participant-card-collapsible-content' },
		attributes = {
			['data-component'] = 'team-participant-card-content'
		},
		children = WidgetUtil.collect(contentChildren)
	}
end

return ParticipantsTeamCard
