---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/CardsGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local ErrorDisplay = Lua.import('Module:Error/Display')

local Component = Lua.import('Module:Widget/Component')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local ParticipantsTeamCard = Lua.import('Module:Widget/Participants/Team/Card')
local ParticipantControls = Lua.import('Module:Widget/Participants/Team/ParticipantControls')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ParticipantsTeamCardsGroupProps
---@field participants TeamParticipant[]|nil
---@field brokenParticipants TeamParticipant[]|nil
---@field showPlayerInfo boolean
---@field showControls boolean
---@field mergeStaffTabIfOnlyOneStaff boolean|nil

---@param props ParticipantsTeamCardsGroupProps
---@return VNode?
local function ParticipantsTeamCardsGroup(props)
	local participants = props.participants
	if not participants then
		return
	end

	local showControls = props.showControls
	local brokenParticipants = props.brokenParticipants or {}

	local errorBoxes = Array.map(brokenParticipants, function(broken)
		return ErrorDisplay.Box{text = broken.errorMessage}
	end)

	local children = WidgetUtil.collect(
		errorBoxes,
		showControls and ParticipantControls{showPlayerInfo = props.showPlayerInfo} or nil,
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

return Component.component(ParticipantsTeamCardsGroup)
