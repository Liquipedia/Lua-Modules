---
-- @Liquipedia
-- page=Module:Widget/ExternalMedia/FormLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Page = Lua.import('Module:Page')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

local FORM_NAME = 'ExternalMediaLinks'

---@class ExternalMediaFormLink: Widget
---@operator call(table?): ExternalMediaFormLink
local ExternalMediaFormLink = Class.new(Widget)

---@return Widget
function ExternalMediaFormLink:render()
	assert(Page.exists('\'Form:' .. FORM_NAME), 'Form:' .. FORM_NAME .. '\' does not exist')
	return HtmlWidgets.Div{
		css = {
			display = 'block',
			['text-align'] = 'center',
			padding = '0.5em',
		},
		children = HtmlWidgets.Div{
			css = {
				display = 'inline',
				['white-space'] = 'nowrap',
			},
			children = {
				mw.text.nowiki('['),
				Link{link = 'Special:FormEdit/' .. FORM_NAME, children = 'Add an external media link'},
				mw.text.nowiki(']'),
			}
		}
	}
end

return ExternalMediaFormLink
