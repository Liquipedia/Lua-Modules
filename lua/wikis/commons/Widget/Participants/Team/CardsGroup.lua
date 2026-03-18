---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/CardsGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local ParticipantsTeamCard = Lua.import('Module:Widget/Participants/Team/Card')
local ParticipantControls = Lua.import('Module:Widget/Participants/Team/ParticipantControls')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ParticipantsTeamCardsGroupProps
---@field participants TeamParticipant[]|nil
---@field showPlayerInfo boolean
---@field showControls boolean
---@field mergeStaffTabIfOnlyOneStaff boolean|nil

---@class ParticipantsTeamCardsGroup: Widget
---@operator call(ParticipantsTeamCardsGroupProps): ParticipantsTeamCardsGroup
---@field props ParticipantsTeamCardsGroupProps
local ParticipantsTeamCardsGroup = Class.new(Widget)

---@return Widget?
function ParticipantsTeamCardsGroup:render()
	local participants = self.props.participants
	if not participants then
		return
	end

	local showControls = self.props.showControls

	local children = WidgetUtil.collect(
		showControls and ParticipantControls{showPlayerInfo = self.props.showPlayerInfo} or nil,
		AnalyticsWidget{
			analyticsName = 'Team participants card',
			children = Div{
				classes = { 'team-participant__grid' },
				children = Array.map(participants, function(participant)
					return ParticipantsTeamCard{
						participant = participant,
					}
				end),
			}
		}
	)

	return Div{
		classes = { 'team-participant' },
		children = children
	}
end

return ParticipantsTeamCardsGroup
