---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/ParticipantNotification
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@param props {text: string?, highlighted: boolean?}
---@return VNode?
local function ParticipantNotification(props)
	local text = props.text
	local highlighted = props.highlighted

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

return Component.component(ParticipantNotification)
