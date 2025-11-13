---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/QualifierInfo
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

	local getIconToDisplay = function()
		if qualification.type == 'tournament' then
			return LeagueIcon.display{
				icon = qualification.tournament.icon,
				iconDark = qualification.tournament.iconDark,
				link = qualification.tournament.pageName,
				options = {noTemplate = true},
			}
		elseif qualification.type == 'external' then
			return Icon{iconName = 'external_link', additionalClasses = { 'team-participant-card-qualifier-external-link-icon' } }
		end
	end

	local getLinkPage = function()
		if qualification.type == 'tournament' then
			return qualification.tournament.pageName
		elseif qualification.type == 'external' then
			return qualification.url
		end
	end

	local getDisplayText = function()
		if qualification.text then
			return qualification.text
		elseif qualification.type == 'tournament' then
			return qualification.tournament.displayName
		end
	end

	local text = getDisplayText()
	local link = getLinkPage()

	if not text then
		return
	end

	return Div{
		classes = {'team-participant-card-qualifier', 'team-participant-card-qualifier--' .. location},
		children = WidgetUtil.collect(
			getIconToDisplay(),
			Span{
				classes = { 'team-participant-card-qualifier-details' },
				children = {
					link and Link{
						link = getLinkPage(),
						children = getDisplayText(),
						linktype = qualification.type == 'external' and 'external' or 'internal',
					} or text,
				}
			}
		)
	}
end

return ParticipantsTeamQualifierInfo
