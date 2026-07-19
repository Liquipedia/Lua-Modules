---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/QualifierInfo
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local LeagueIcon = Lua.import('Module:LeagueIcon')
local Placement = Lua.import('Module:Placement')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Span = Html.Span
local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@param props {participant: TeamParticipant, location: 'card'|'list'}
---@return VNode?
local function ParticipantsTeamQualifierInfo(props)
	local participant = props.participant
	local location = props.location
	local qualification = participant.qualification

	if not qualification then
		return
	end

	local text = qualification.text
	if not text and qualification.type == 'tournament' then
		text = qualification.tournament.displayName
	end

	if not text then
		return
	end

	local link, icon, linktype
	if qualification.type == 'tournament' then
		link = qualification.tournament.pageName
		icon = LeagueIcon.display{
			icon = qualification.tournament.icon,
			iconDark = qualification.tournament.iconDark,
			options = {noTemplate = true, noLink = true},
		}
		linktype = 'internal'
	elseif qualification.type == 'external' then
		link = qualification.url
		icon = Icon{
			iconName = 'external_link',
			additionalClasses = { 'team-participant-card__qualifier-icon' }
		}
		linktype = 'external'
	elseif qualification.type == 'internal' then
		link = qualification.page
		icon = Icon{
			iconName = 'internal_link',
			additionalClasses = { 'team-participant-card__qualifier-icon' }
		}
	end

	local textChildren = {text}
	if link then
		textChildren = {
			Link{
				link = link,
				linktype = linktype,
				children = text,
			}
		}
	end

	return Div{
		classes = {'team-participant-card__qualifier', 'team-participant-card__qualifier--' .. location},
		children = {
			Div{
				classes = {'team-participant-card__qualifier-content'},
				children = WidgetUtil.collect(
					icon,
					Span{
						classes = {'team-participant-card__qualifier-details'},
						children = textChildren
					}
				)
			},
			Placement.renderInWidget{placement = qualification.placement}
		}
	}
end

return Component.component(ParticipantsTeamQualifierInfo)
