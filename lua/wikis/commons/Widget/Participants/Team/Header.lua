---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
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

	local isTbdOpponent = Opponent.isTbd(participant.opponent)
	local isQualificationTournament = participant.qualification and participant.qualification.type == 'tournament'

	local opponentClasses = {'team-participant-card__opponent', 'team-participant-card__opponent--square-icon'}
	local opponentDisplay

	if isTbdOpponent and isQualificationTournament then
		opponentDisplay = Div{
			classes = opponentClasses,
			children = WidgetUtil.collect(
				LeagueIcon.display{
					icon = participant.qualification.tournament.icon,
					iconDark = participant.qualification.tournament.iconDark,
					options = {
						noTemplate = true,
						noLink = true,
						defaultLink = participant.qualification.tournament.pageName,
					},
				},
				'TBD'
			)
		}
	else
		opponentDisplay = OpponentDisplay.BlockOpponent{
			opponent = participant.opponent,
			teamStyle = 'standard',
			additionalClasses = opponentClasses
		}
	end

	return Div{
		classes = { 'team-participant-card__header' },
		children = {
			Div{
				classes = {'team-participant-card__header-main'},
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
	local isTbd = Logic.isNotEmpty(participant.potentialQualifiers) or Opponent.isTbd(participant.opponent);
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
		classes = {
			'team-participant-card__label',
			isTbd and 'team-participant-card__label--tbd' or ''
		},
		children = {
			HtmlWidgets.Span{
				children = { labelText }
			}
		}
	}
end

return ParticipantsTeamHeader
