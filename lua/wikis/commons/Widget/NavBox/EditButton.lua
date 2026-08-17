---
-- @Liquipedia
-- page=Module:Widget/NavBox/EditButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local Widget = Lua.import('Module:Widget')

---@class NavBoxEditButton: Widget
---@operator call(table): NavBoxEditButton
local NavBoxEditButton = Class.new(Widget)

---@return Widget?
function NavBoxEditButton:render()
	if not self.props.templateLink then return end

	return Html.Span{
		classes = {'navigation-not-searchable'},
		css = {float = 'left', ['font-size'] = 'xx-small', padding = 0},
		children = {
			mw.text.nowiki('['),
			Link{
				link = 'Special:EditPage/Template:' .. self.props.templateLink,
				children = {'e'},
			},
			mw.text.nowiki(']'),
		}
	}
end

return NavBoxEditButton
