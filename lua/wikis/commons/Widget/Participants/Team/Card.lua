---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local LeagueIcon = Lua.import('Module:LeagueIcon')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span
local Link = Lua.import('Module:Widget/Basic/Link')
local ParticipantsTeamHeader = Lua.import('Module:Widget/Participants/Team/Header')
local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')

---@class ParticipantsTeamCard: Widget
---@operator call(table): ParticipantsTeamCard
local ParticipantsTeamCard = Class.new(Widget)

---@return Widget
function ParticipantsTeamCard:render()
	local participant = self.props.participant
	local variant = self.props.variant or 'compact'

	local qualifierBoxHeader = self:_renderQualifierBox(participant, 'header')
	local qualifierBoxContent = self:_renderQualifierBox(participant, 'content')
	local content = { self:_renderContent(participant) }

	local header = ParticipantsTeamHeader{
		participant = participant,
	}

	local collapsible = Collapsible{
		shouldCollapse = true,
		collapseAreaClasses = {'team-participant-card-collapsible-content'},
		classes = {'team-participant-card'},
	}

	collapsible.props.titleWidget = Div{
		children = {
			header,
			qualifierBoxHeader
		}
	}
	table.insert(content, 1, qualifierBoxContent)
	collapsible.props.children = content

	return collapsible
end

---@private
---@param participant TeamParticipantsEntity
---@param location string
---@return Widget?
function ParticipantsTeamCard:_renderQualifierBox(participant, location)
	-- TODO: Implement qualifier box content based on figma
	if participant.qualifierPage or participant.qualifierUrl or participant.qualifierText then
		return Div{
			classes = {'team-participant-card-qualifier', 'team-participant-card-qualifier--' .. location},
			children = WidgetUtil.collect(
				LeagueIcon.display{
					-- icon = participant.qualifierIcon,
					-- iconDark = participant.qualifierIconDark,
					link = participant.qualifierUrl,
					options = {noTemplate = true},
				},
				Span{
					classes = { 'team-participant-card-qualifier-details' },
					children = {
						Link{
							link = participant.qualifierPage,
							children = participant.qualifierText
						}
					}
				}
			)
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
