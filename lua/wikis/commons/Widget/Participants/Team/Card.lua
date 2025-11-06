---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local ParticipantsTeamHeader = Lua.import('Module:Widget/Participants/Team/Header')

---@class ParticipantsTeamCard: Widget
---@operator call(table): ParticipantsTeamCard
local ParticipantsTeamCard = Class.new(Widget)

---@return Widget
function ParticipantsTeamCard:render()
	local participant = self.props.participant

	return Div{
		classes = { 'team-participant-card', 'is--collapsed' }, -- Hardcoded collapsed state until we implement the js
		attributes = {
			['data-component'] = 'team-participant-card'
		},
		children = WidgetUtil.collect(
			ParticipantsTeamHeader{participant = participant},
			self:_renderContent(participant)
		)
	}
end

-- TODO: This will be divided to multiple components
---@private
---@param participant TeamParticipantsEntity
---@return Widget
function ParticipantsTeamCard:_renderContent(participant)
	-- TODO: Implement qualifier box, roster functionality & notes
	return Div{
		classes = { 'team-participant-card-collapsible-content' },
		attributes = {
			['data-component'] = 'team-participant-card-content'
		},
		children = { participant.opponent.name } -- Team details & roster here
	}
end

return ParticipantsTeamCard
