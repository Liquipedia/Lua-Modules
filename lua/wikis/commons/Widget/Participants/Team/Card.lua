---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local Div = Lua.import('Module:Widget/Html/All').Div
local TeamHeader = Lua.import('Module:Widget/Participants/Team/Header')
local TeamQualifierInfo = Lua.import('Module:Widget/Participants/Team/QualifierInfo')
local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')

---@class ParticipantsTeamCard: Widget
---@operator call(table): ParticipantsTeamCard
local ParticipantsTeamCard = Class.new(Widget)

---@return Widget
function ParticipantsTeamCard:render()
	local participant = self.props.participant

	local qualifierInfoHeader = TeamQualifierInfo{participant = participant, location = 'header'}
	local qualifierInfoContent = TeamQualifierInfo{participant = participant, location = 'content'}
	local content = { self:_renderContent(participant) }

	local header = TeamHeader{
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
			qualifierInfoHeader
		}
	}
	table.insert(content, 1, qualifierInfoContent)
	collapsible.props.children = content

	return collapsible
end

---@private
---@param participant TeamParticipantsEntity
---@return Widget
function ParticipantsTeamCard:_renderContent(participant)
	return Div{
		classes = { 'team-participant-card-collapsible-content' },
		children = { participant.opponent.name } -- Team roster & notes here
	}
end

return ParticipantsTeamCard
