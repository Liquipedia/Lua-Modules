---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Components/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param props {titleText: string, buttonText: string?, buttonArea: integer?, hasSeed: boolean}
---@return VNode[]
local function render(props)
	return WidgetUtil.collect(
		props.hasSeed and Html.Span{
			classes = {'toggle-area-button', 'button', 'button--small', 'button--primary'},
			css = {position = 'absolute'},
			attributes = {['data-toggle-area-btn'] = props.buttonArea},
			children = props.buttonText,
		} or nil,
		Html.Div{
			classes = {'participantTable-title'},
			children = props.titleText,
		}
	)
end

return Component.component(render)
