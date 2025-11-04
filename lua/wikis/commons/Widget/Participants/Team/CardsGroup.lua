---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/CardsGroup
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local TeamParticipantsRepository = Lua.import('Module:TeamParticipants/Repository')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class ParticipantsTeamCard: Widget
---@operator call(table): ParticipantsTeamCard
local ParticipantsTeamCard = Class.new(Widget)

---@return Widget?
function ParticipantsTeamCard:render()
	local participants = TeamParticipantsRepository.getAllByPageName(self.props.pageName)
	if not participants then
		return
	end

	return AnalyticsWidget{
		analyticsName = 'Team participants card',
		children = Array.map(participants, function(participant)
			return HtmlWidgets.Div{
				children = OpponentDisplay.BlockOpponent{opponent = participant.opponent},
			}
		end),
	}
end

return ParticipantsTeamCard
