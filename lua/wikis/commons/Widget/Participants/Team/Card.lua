---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local ParticipantsTeamHeader = Lua.import('Module:Widget/Participants/Team/Header')
local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')

---@class ParticipantsTeamCard: Widget
---@operator call(table): ParticipantsTeamCard
local ParticipantsTeamCard = Class.new(Widget)

---@return Widget
function ParticipantsTeamCard:render()
	local participant = self.props.participant
	local variant = self.props.variant or 'compact'

	local qualifierBox = self:_renderQualifierBox(participant)
	local content = { self:_renderContent(participant) }

	local header = ParticipantsTeamHeader{
		participant = participant,
		variant = variant
	}

	local collapsible = Collapsible{
		shouldCollapse = true,
		collapseAreaClasses = {'team-participant-card-collapsible-content'},
		classes = {'team-participant-card', 'team-participant-card--' .. variant},
	}

	if variant == 'expanded' then
		collapsible.props.titleWidget = Div{
			children = {
				header,
				qualifierBox
			}
		}
		collapsible.props.children = content
	else
		collapsible.props.titleWidget = header
		if qualifierBox then
			table.insert(content, 1, qualifierBox)
		end
		collapsible.props.children = content
	end

	return collapsible
end

---@private
---@param participant TeamParticipantsEntity
---@return Widget?
function ParticipantsTeamCard:_renderQualifierBox(participant)
	-- TODO: Implement qualifier box content based on figma
	if participant.qualifierPage or participant.qualifierUrl or participant.qualifierText then
		return Div{
			classes = {'team-participant-card-qualifier'},
			children = {'Qualifier Info Box Placeholder'}
		}
	end
end

-- TODO: This will be divided to multiple components
---@private
---@param participant TeamParticipantsEntity
---@return Widget
function ParticipantsTeamCard:_renderContent(participant)
	-- TODO: Implement qualifier box, roster functionality & notes
	return Div{
		classes = { 'team-participant-card-collapsible-content' },
		children = { participant.opponent.name } -- Team details & roster here
	}
end

return ParticipantsTeamCard
