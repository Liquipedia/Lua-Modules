---
-- @Liquipedia
-- page=Module:Widget/NavBox/EditButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

---@param props {templateLink: string?}
---@return VNode?
local function NavBoxEditButton(props)
	if not props.templateLink then return end

	return Html.Span{
		classes = {'navigation-not-searchable'},
		css = {float = 'left', ['font-size'] = 'xx-small', padding = 0},
		children = {
			mw.text.nowiki('['),
			Link{
				link = 'Special:EditPage/Template:' .. props.templateLink,
				children = {'e'},
			},
			mw.text.nowiki(']'),
		}
	}
end

return Component.component(NavBoxEditButton)
