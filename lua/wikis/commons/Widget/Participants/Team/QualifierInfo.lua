---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/QualifierInfo
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Ordinal = Lua.import('Module:Ordinal')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span
local Link = Lua.import('Module:Widget/Basic/Link')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class ParticipantsTeamQualifierInfo: Widget
---@field props {participant: TeamParticipant, location: 'card'|'list'}
---@operator call(table): ParticipantsTeamQualifierInfo
local ParticipantsTeamQualifierInfo = Class.new(Widget)

---@return Widget?
function ParticipantsTeamQualifierInfo:render()
	local participant = self.props.participant
	local location = self.props.location
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
			additionalClasses = { 'team-participant-card-qualifier-external-link-icon' }
		}
		linktype = 'external'
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

	local content = Div{
		classes = {'team-participant-card-qualifier', 'team-participant-card-qualifier--' .. location},
		children = {
			Div{
				classes = {'team-participant-card-qualifier-content'},
				children = WidgetUtil.collect(
					icon,
					Span{
						classes = {'team-participant-card-qualifier-details'},
						children = textChildren
					}
				)
			},
			self:createPlacementBadge(qualification.placement)
		}
	}

	return content
end

---@param placement number?
---@return Widget?
function ParticipantsTeamQualifierInfo:createPlacementBadge(placement)
	if not placement then
		return nil
	end

	return Span{
		classes = {'team-participant-card-qualifier-placement'},
		children = {Ordinal.toOrdinal(placement)}
	}
end

return ParticipantsTeamQualifierInfo
