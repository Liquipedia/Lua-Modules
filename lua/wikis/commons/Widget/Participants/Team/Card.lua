---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local TeamHeader = Lua.import('Module:Widget/Participants/Team/Header')
local ParticipantNotification = Lua.import('Module:Widget/Participants/Team/ParticipantNotification')
local TeamQualifierInfo = Lua.import('Module:Widget/Participants/Team/QualifierInfo')
local ParticipantsTeamRoster = Lua.import('Module:Widget/Participants/Team/Roster')
local PotentialQualifiers = Lua.import('Module:Widget/Participants/Team/PotentialQualifiers')
local WarningBoxGroup = Lua.import('Module:Widget/WarningBox/Group')

---@class ParticipantsTeamCard: Widget
---@operator call(table): ParticipantsTeamCard
local ParticipantsTeamCard = Class.new(Widget)

---@return Widget
function ParticipantsTeamCard:render()
	local participant = self.props.participant

	local qualifierInfoHeader = TeamQualifierInfo{participant = participant, location = 'header'}
	local qualifierInfoContent = TeamQualifierInfo{participant = participant, location = 'content'}

	local content = {}

	if participant.warnings then
		table.insert(content, WarningBoxGroup{data = participant.warnings})
	end

	table.insert(content, qualifierInfoContent)
	table.insert(content, PotentialQualifiers{participant = participant})
	table.insert(content, ParticipantsTeamRoster{participant = participant})
	table.insert(content, Div{
		classes = {'team-participant-notifications'},
		children = Array.map(participant.notes, function(note)
			return ParticipantNotification{
				text = note.text,
				highlighted = note.highlighted,
			}
		end)
	})

	return Collapsible{
		shouldCollapse = true,
		collapseAreaClasses = {'team-participant-card-collapsible-content'},
		classes = {'team-participant-card'},
		titleWidget = Div{
			children = {
				TeamHeader{
					participant = participant,
				},
				qualifierInfoHeader
			}
		},
		children = content
	}
end

return ParticipantsTeamCard
