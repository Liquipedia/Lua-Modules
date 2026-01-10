---
-- @Liquipedia
-- page=Module:Widget/Basic/Dialog
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class DialogWidgetProps
---@field title? string|number|Widget|Html|(string|number|Widget|Html)[]
---@field trigger? string|number|Widget|Html|(string|number|Widget|Html)[]
---@field children? string|number|Widget|Html|(string|number|Widget|Html)[]

---@class DialogWidget: Widget
---@operator call(DialogWidgetProps): DialogWidget
---@field props DialogWidgetProps
local DialogWidget = Class.new(Widget)

---@return Widget?
function DialogWidget:render()
	local props = self.props
	if Logic.isEmpty(props.title) or Logic.isEmpty(props.trigger) or Logic.isEmpty(props.children) then
		return
	end
	return Div{
		classes = {'general-dialog'},
		children = {
			Div{
				classes = {'general-dialog-trigger'},
				children = props.trigger
			},
			Div{
				classes = {'general-dialog-title'},
				children = props.title
			},
			Div{
				classes = {'general-dialog-wrapper'},
				children = props.children
			}
		}
	}
end

return DialogWidget
