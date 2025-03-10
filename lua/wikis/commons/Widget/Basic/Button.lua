---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Basic/Button
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Div = HtmlWidgets.Div

---@class ButtonWidgetParameters
---@field title string?
---@field link string?
---@field linktype 'internal'|'external'|nil
---@field variant 'primary'|'secondary'|'ghost'|nil
---@field size 'sm'|'md'|'lg'|nil

---@class ButtonWidget: Widget
---@operator call(ButtonWidgetParameters): ButtonWidget

local Button = Class.new(Widget)
Button.defaultProps = {
	linktype = 'internal',
	variant = 'primary',
	size = 'md',
}

---@return Widget
function Button:render()
	--- MW Parser does not allowed the <button> tag, so we use a DIV for now instead
	local cssClasses = {
		'btn',
		'btn-new',
	}
	if self.props.variant == 'primary' then
		table.insert(cssClasses, 'btn-primary')
	elseif self.props.variant == 'secondary' then
		table.insert(cssClasses, 'btn-secondary')
	end

	if self.props.size == 'sm' then
		table.insert(cssClasses, 'btn-small')
	elseif self.props.size == 'lg' then
		table.insert(cssClasses, 'btn-large')
	end

	local button = Div{
		classes = Array.extend(cssClasses, self.props.classes or {}),
		attributes = Table.merge({
			title = self.props.title,
			['aria-label'] = self.props.title,
			role = 'button',
			tabindex = '0',
		}, self.props.attributes or {}),
		children = self.props.children,
	}

	if not self.props.link then
		return button
	end

	-- Have to wrap it in an extra div to prevent the mediawiki parser from messing it up
	return Div{children = {
		Link{
			link = self.props.link,
			linktype = self.props.linktype,
			children = {button},
		}
	}}
end

return Button
