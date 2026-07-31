---
-- @Liquipedia
-- page=Module:Widget/Basic/Dialog
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class DialogWidgetProps
---@field dialogClasses? string[]
---@field title? Renderable|Renderable[]
---@field trigger? Renderable|Renderable[]
---@field children? Renderable|Renderable[]

---@param props DialogWidgetProps
---@return HtmlNode?
local function DialogWidget(props)
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

return Component.component(DialogWidget)
