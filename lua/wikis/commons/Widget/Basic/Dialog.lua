---
-- @Liquipedia
-- page=Module:Widget/Basic/Dialog
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class DialogWidgetProps
---@field dialogClasses? string[]
---@field title? Renderable|Renderable[]
---@field trigger? Renderable|Renderable[]
---@field children? Renderable|Renderable[]

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
		attributes = {
			['data-dialog-additional-classes'] = table.concat(
				Array.extend('general-dialog-container', props.dialogClasses),
				' '
			),
		},
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
