---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Navbox/Navbar
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('commons.Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class NavbarParameters
---@field collapsible boolean?
---@field mini boolean?
---@field plain boolean?
---@field style table<string, string>?
---@field title string?
---@field fontClasses string[]?
---@field fontStyle table<string, string>?
---@field text string?
---@field noedit boolean?

---@class Navbar: Widget
---@operator call(table): Navbar
---@field props NavbarParameters
---@field title Title?
local Navbar = Class.new(Widget)
Navbar.defaultProps = {
	title = ':' .. mw.getCurrentFrame():getParent():getTitle(),
	text = 'This box:'
}

---@return Widget
function Navbar:render()
	self.title = mw.title.new(String.trim(self.props.title), 'Template');
	assert(self.title, 'Invalid title ' .. self.props.title)

	local classes = { 'noprint', 'plainlinks', 'navbox-navbar' }
	local cssProperties = Table.merge({
		--background = 'none',
		padding = 0,
		['font-size'] = 'xx-small'
	}, self.props.style)
	local children = {}

	if Logic.readBool(args.mini) then
		Array.appendWith(classes, 'mini')
	end

	if not (args.mini or args.plain) then
		Array.appendWith(children, Span{
			classes = self.props.fontClasses,
			css = Table.merge({ ['word-spacing'] = 0 }, self.props.fontStyle),
			children = {
				self.props.text,
				' '
			}
		})
	end

	

	return Div{
		classes = classes,
		css = cssProperties,
		children = WidgetUtil.collect(children)
	}
end

