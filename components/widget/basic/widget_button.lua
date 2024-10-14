---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Button
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Link')
local Div = HtmlWidgets.Div

---@class ButtonWidgetParameters
---@field title string?
---@field link string?
---@field linktype 'internal'|'external'|nil
---@field variant 'primary'|'secondary'|'ghost'|nil
---@field size 'sm'|'md'|'lg'|nil

---@class ButtonWidget: Widget
---@operator call(ButtonWidgetParameters): ButtonWidget

local Button = Class.new(
	Widget,
	function(self, input)
		self.title = input.title
		self.link = input.link
		self.linktype = input.linktype or 'internal'
		self.variant = input.variant or 'primary'
		self.size = input.size or 'md'
	end
)

---@return Widget
function Button:render(children)
	--- MW Parser does not allowed the <button> tag, so we use a DIV for now instead
	local cssClasses = {
		'btn',
		'btn-new',
	}
	if self.props.variant == 'primary' or self.props.variant == nil then
		table.insert(cssClasses, 'btn-primary')
	elseif self.props.variant == 'secondary' then
		table.insert(cssClasses, 'btn-secondary')
	end

	if self.size == 'sm' then
		table.insert(cssClasses, 'btn-small')
	elseif self.size == 'lg' then
		table.insert(cssClasses, 'btn-large')
	end

	local button = Div{
		attributes = {
			class = table.concat(cssClasses, ' '),
			title = self.title,
			['aria-label'] = self.title,
			role = 'button',
			tabindex = '0',
		},
		children = children,
	}

	if not self.link then
		return button
	end

	-- Have to wrap it in an extra div to prevent the mediawiki parser from messing it up
	return Div{children = {
		Link{
			link = self.link,
			linktype = self.linktype,
			children = {button},
		}
	}}
end

return Button
