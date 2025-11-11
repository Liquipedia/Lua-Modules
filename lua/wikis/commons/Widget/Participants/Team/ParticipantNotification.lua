---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/ParticipantNotification
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class ParticipantNotification: Widget
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
			'participant-notification',
			highlighted and 'participant-notification-highlighted' or nil,
		},
		children = {
			Icon{iconName = 'info'}, -- TODO use/make icon that exists
			Div{
				classes = {'participant-notification-text'},
				children = {text}
			}
		}
	}
end

return ParticipantNotification
