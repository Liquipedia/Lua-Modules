---
-- @Liquipedia
-- page=Module:Widget/NavBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local CollapsibleToggle = Lua.import('Module:Widget/GeneralCollapsible/Toggle')
local EditButton = Lua.import('Module:Widget/NavBox/EditButton')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local B = HtmlWidgets.B
local Div = HtmlWidgets.Div
local Widget = Lua.import('Module:Widget')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local NavBoxChild = Lua.import('Module:Widget/NavBox/Child')

---@class NavBox: Widget
---@operator call(table): NavBox
local NavBox = Class.new(Widget)

---@return Widget
function NavBox:render()
	local props = self.props

	-- if the NavBox is sometimes used as a child in another NavBox return the props as Json
	if Logic.readBool(props.isChild) then
		return Json.stringify(props)
	end

	assert(props.title, 'Missing title input')
	assert(props.child1, 'No children inputted')

	-- as a first step collapse at the top and uncollapse at the bottom
	-- as heuristic assume we are at the bottom if an infobox or HDB is above
	local shouldCollapse = Logic.readBool(Table.extract(props, 'collapsed')) or not (
		Variables.varDefault('has_infobox') -- any page with an infobox
		or Variables.varDefault('tournament_parent') -- any Page with a HDB
	)

	-- have to extract so the child doesn't add the header too ...
	local title = Table.extract(self.props, 'title')
	assert(title, 'Missing "|title="')

	return Collapsible{
		attributes = {
			['aria-labelledby'] = title:gsub(' ', '_'),
			role = 'navigation',
			['data-nosnippet'] = 0,
		},
		classes = {
			'navigation-not-searchable',
			'navbox',
			Logic.readBool(props.hideonmobile) and 'mobile-hide' or nil
		},
		shouldCollapse = shouldCollapse,
		titleWidget = NavBox._title(title, self.props.titleLink, self.props.template),
		children = {NavBoxChild(props)},
	}
end

---@param titleText string
---@param titleLink string
---@param templateLink string?
---@return Widget
function NavBox._title(titleText, titleLink, templateLink)
	return Div{
		classes = {'navbox-title'},
		children = WidgetUtil.collect(
			EditButton{templateLink = templateLink},
			B{children = {
				titleLink and Link{link = titleLink, children = titleText} or titleText
			}},
			CollapsibleToggle{css = {float = 'right'}}
		)
	}
end

return NavBox
