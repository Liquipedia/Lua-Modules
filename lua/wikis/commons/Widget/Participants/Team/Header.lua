---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')
local ChevronToggle = Lua.import('Module:Widget/GeneralCollapsible/ChevronToggle')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

local ParticipantsTeamHeader = {}

---@param props {participant: TeamParticipant}
---@return VNode
function ParticipantsTeamHeader.render(props)
	local participant = props.participant
	local labelDiv = ParticipantsTeamHeader._renderLabel(participant)

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
		opponentDisplay = Div{
			classes = {'team-participant-card__opponent'},
			children = {
				Div{
					classes = {'team-participant-card__opponent-compact'},
					children = {
						OpponentDisplay.BlockOpponent{
							opponent = participant.opponent,
							teamStyle = 'bracket',
							additionalClasses = opponentClasses,
						}
					}
				},
				Div{
					classes = {'team-participant-card__opponent-full'},
					children = {
						OpponentDisplay.BlockOpponent{
							opponent = participant.opponent,
							teamStyle = 'standard',
							additionalClasses = opponentClasses,
						}
					}
				}
			}
		}
	end

	return Div{
		classes = { 'team-participant-card__header' },
		attributes = {['data-collapsible-click-region'] = 'true'},
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
---@return VNode?
function ParticipantsTeamHeader._renderLabel(participant)
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
			isTbd and 'team-participant-card__label--tbd' or nil
		},
		children = {
			Html.Span{
				children = { labelText }
			}
		}
	}
end

return Component.component(ParticipantsTeamHeader.render)
