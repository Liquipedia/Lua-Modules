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

---@class ParticipantsTeamQualifierInfo: Widget
---@operator call(table): ParticipantsTeamQualifierInfo
local ParticipantsTeamQualifierInfo = Class.new(Widget)

---@return Widget?
function ParticipantsTeamQualifierInfo:render()
	local participant = self.props.participant
	local location = self.props.location

	if not participant.qualifierPage or not participant.qualifierUrl or not participant.qualifierText then
		return
	end

	return Div{
		classes = {'team-participant-card-qualifier', 'team-participant-card-qualifier--' .. location},
		children = WidgetUtil.collect(
			-- TODO: Get the qualifier tournament icon
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

return ParticipantsTeamQualifierInfo
