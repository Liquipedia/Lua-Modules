---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local I18n = Lua.import('Module:I18n')

local Component = Lua.import('Module:Widget/Component')
local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Html = Lua.import('Module:Widget/Html')
local B = Html.B
local Div = Html.Div
local Span = Html.Span
local TeamHeader = Lua.import('Module:Widget/Participants/Team/Header')
local ParticipantNotification = Lua.import('Module:Widget/Participants/Team/ParticipantNotification')
local TeamQualifierInfo = Lua.import('Module:Widget/Participants/Team/QualifierInfo')
local ParticipantsTeamRoster = Lua.import('Module:Widget/Participants/Team/Roster')
local PotentialQualifiers = Lua.import('Module:Widget/Participants/Team/PotentialQualifiers')
local WarningBoxGroup = Lua.import('Module:Widget/WarningBox/Group')

---@param props {participant: TeamParticipant, mergeStaffTabIfOnlyOneStaff: boolean?}
---@return Renderable
local function ParticipantsTeamCard(props)
	local participant = props.participant

	local qualifierInfoHeader = TeamQualifierInfo{participant = participant, location = 'header'}
	local qualifierInfoContent = TeamQualifierInfo{participant = participant, location = 'content'}

	local content = {
		Div{
			classes = {'team-participant-card__hover-header'},
			children = I18n.translate('participants-hover-roster-label'),
		},
	}

	if participant.warnings then
		table.insert(content, WarningBoxGroup{data = participant.warnings})
	end

	table.insert(content, qualifierInfoContent)
	table.insert(content, PotentialQualifiers{participant = participant})
	table.insert(content, ParticipantsTeamRoster{
		participant = participant,
		mergeStaffTabIfOnlyOneStaff = props.mergeStaffTabIfOnlyOneStaff
	})

	if participant.notes and #participant.notes > 0 then
		table.insert(content, Collapsible{
			shouldCollapse = true,
			classes = {'team-participant-card__notes'},
			collapseAreaClasses = {'team-participant-card__notifications'},
			titleWidget = Div{
				classes = {'team-participant-card__notes-header'},
				attributes = {['data-collapsible-click-region'] = 'true'},
				children = {
					B{children = I18n.translate('participants-notes-label', {count = #participant.notes})},
					Span{
						classes = {'team-participant-card__notes-toggle'},
						children = {Icon{iconName = 'expand'}},
					},
				},
			},
			children = Array.map(participant.notes, function(note)
				return ParticipantNotification{
					text = note.text,
					highlighted = note.highlighted,
				}
			end)
		})
	end

	return Collapsible{
		shouldCollapse = true,
		collapseAreaClasses = {'team-participant-card__content'},
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

return Component.component(ParticipantsTeamCard)
