---
-- @Liquipedia
-- page=Module:Widget/Basic/CopyToClipboard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Span = HtmlWidgets.Span

---@class CopyToClipboardProps
---@field children Renderable|Renderable[]?
---@field textToCopy string? text to be copied to clipboard
---@field successText string?

---@class CopyToClipboardWidget: Widget
---@operator call(CopyToClipboardProps): CopyToClipboardWidget
---@field props CopyToClipboardProps
local CopyToClipboard = Class.new(Widget)

---@return Widget
function CopyToClipboard:render()
	local props = self.props
	return Span{
		classes = {'copy-to-clipboard'},
		attributes = {['data-copied-text'] = props.successText},
		children = {
			Span{
				classes = {'copy-this'},
				children = self.props.textToCopy,
			},
			Span{
				classes = {'see-this'},
				children = self.props.children,
			}
		}
	}
end

return CopyToClipboard
