---
-- @Liquipedia
-- page=Module:Widget/Basic/CopyToClipboard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Span = Html.Span

---@class CopyToClipboardProps
---@field children Renderable|Renderable[]?
---@field textToCopy string? text to be copied to clipboard
---@field successText string?

---@param props CopyToClipboardProps
---@return HtmlNode
local function CopyToClipboard(props)
	return Span{
		classes = {'copy-to-clipboard'},
		attributes = {['data-copied-text'] = props.successText},
		children = {
			Span{
				classes = {'copy-this'},
				children = props.textToCopy,
			},
			Span{
				classes = {'see-this'},
				children = props.children,
			}
		}
	}
end

return Component.component(CopyToClipboard)
