---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/CardsGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local ParticipantsTeamCard = Lua.import('Module:Widget/Participants/Team/Card')
local ParticipantControls = Lua.import('Module:Widget/Participants/Team/ParticipantControls')
local WidgetUtil = Lua.import('Module:Widget/Util')

local teamParticipantsVars = PageVariableNamespace('TeamParticipants')

---@class ParticipantsTeamCardsGroupProps
---@field participants TeamParticipant[]|nil
---@field playerinfo boolean|string|nil
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

	local showSwitches = not teamParticipantsVars:get('externalControlsRendered')

	local children = WidgetUtil.collect(
		showSwitches and ParticipantControls{playerinfo = self.props.playerinfo, external = false} or nil,
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
