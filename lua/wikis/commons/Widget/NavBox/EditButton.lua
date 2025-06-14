---
-- @Liquipedia
-- page=Module:Widget/NavBox/EditButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Widget = Lua.import('Module:Widget')

---@class NavBoxEditButton: Widget
---@operator call(table): NavBoxEditButton
local NavBoxEditButton = Class.new(Widget)

---@return Widget?
function NavBoxEditButton:render()
	if not self.props.templateLink then return end
	local editLink = HtmlWidgets.Fragment{children = {
		mw.text.nowiki('['),
		Link{
			linktype = 'external',
			link = mw.site.server ..
				tostring(mw.uri.localUrl( 'Template:' .. self.props.templateLink, 'action=edit' )),
			children = {'e'},
		},
		mw.text.nowiki(']'),
	}}

	return HtmlWidgets.Span{
		classes = {'navigation-not-searchable'},
		css = {float = 'left', ['font-size'] = 'xx-small', padding = 0},
		children = {editLink}
	}
end

return NavBoxEditButton
