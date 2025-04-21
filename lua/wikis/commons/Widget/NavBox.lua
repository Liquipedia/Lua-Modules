---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/NavBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

local NavBoxChild = Lua.import('Module:Widget/NavBox/Child')

---@class NavBox: Widget
---@operator call(table): NavBox
---@field props table
local NavBox = Class.new(Widget)

---@return Widget
function NavBox:render()
	local props = self.props

	assert(props.title, 'Missing title input')
	assert(props.child1, 'No children inputted')

	return Div{
		attributes = {
			['aria-labelledby'] = props.title:gsub(' ', '_'),
			role = 'navigation',
			['data-nosnippet'] = 0,
		},
		classes = Array.append({},
			'navigation-not-searchable',
			'navbox',
			Logic.readBool(props.hideonmobile) and 'mobile-hide' or nil
		),
	children = {NavBoxChild(Table.merge(props, {isFirst = true}))}
	}
end

return NavBox
