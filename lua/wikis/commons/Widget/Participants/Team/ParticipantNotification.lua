---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/ParticipantNotification
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class ParticipantNotification: Widget
---@field props {text: string?, highlighted: boolean?}
---@operator call(table): ParticipantNotification
local ParticipantNotification = Class.new(Widget)

---@return Widget?
function ParticipantNotification:render()
	local text = self.props.text
	local highlighted = self.props.highlighted

	if not text then
		return
	end

	return Div{
		classes = {
			'team-participant-card__notification',
			highlighted and 'team-participant-card__notification--highlighted' or nil,
		},
		children = {text}
	}
end

return ParticipantNotification
