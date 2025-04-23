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
local Variables = Lua.import('Module:Variables')

local Widget = Lua.import('Module:Widget')
local CollapsibleToggle = Lua.import('Module:Widget/GeneralCollapsible/Toggle')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local B = HtmlWidgets.B
local Div = HtmlWidgets.Div

local NavBoxChild = Lua.import('Module:Widget/NavBox/Child')

---@class NavBox: Widget
---@operator call(table): NavBox
local NavBox = Class.new(Widget)

---@return Widget
function NavBox:render()
	local props = self.props

	assert(props.title, 'Missing title input')
	assert(props.child1, 'No children inputted')

	-- as a first step collapse at the top and uncollapse at the bottom
	-- as heuristic assume we are at the bottom if an infobox or HDB is above
	local shouldCollapse = not (
		Variables.varDefault('has_infobox') -- any page with an infobox
		or Variables.varDefault('tournament_parent') -- any Page with a HDB
	)

	-- have to extract so the child doesn't add the header too ...
	local title = Table.extract(self.props, 'title')

	return Div{
		attributes = {
			['aria-labelledby'] = title:gsub(' ', '_'),
			role = 'navigation',
			['data-nosnippet'] = 0,
		},
		classes = Array.append({},
			'navigation-not-searchable',
			'navbox',
			'general-collapsible',
			shouldCollapse and 'collapsed' or nil,
			Logic.readBool(props.hideonmobile) and 'mobile-hide' or nil
		),
		children = {
			NavBox._title(title),
			Div{
				children = NavBoxChild(props),
				classes = {'should-collapse'},
			},
		}
	}
end

---@param titleText string
---@return Widget
function NavBox._title(titleText)
	return Div{
		classes = {'navbox-title'},
		children = {
			B{children = {titleText}},
			CollapsibleToggle{css = {float = 'right'}},
		}
	}
end

return NavBox
