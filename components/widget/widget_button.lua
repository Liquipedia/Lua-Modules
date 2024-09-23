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

---@class ButtonWidgetParameters: WidgetParameters
---@field title string?
---@field link string?
---@field linktype 'internal'|'external'|nil
---@field variant 'primary'|'secondary'|'ghost'|nil
---@field size 'sm'|'md'|'lg'|nil

---@class ButtonWidget: Widget
---@operator call(ButtonWidgetParameters): ButtonWidget
---@field title string?
---@field link string?
---@field linktype 'internal'|'external'
---@field variant 'primary'|'secondary'|'ghost'
---@field size 'sm'|'md'|'lg'

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

---@param children string[]
---@return string
function Button:make(children)
	--- MW Parser does not allowed the <button> tag, so we use a div for now instead
	local button = mw.html.create('div'):addClass('btn'):addClass('btn-new')
	button:attr('title', self.title)
	button:attr('aria-label', self.title)
	button:attr('role', 'button')
	button:attr('tabindex', '0')

	button:wikitext(table.concat(children))

	if self.variant == 'primary' then
		button:addClass('btn-primary')
	elseif self.variant == 'secondary' then
		button:addClass('btn-secondary')
	end

	if self.size == 'sm' then
		button:addClass('btn-small')
	elseif self.size == 'lg' then
		button:addClass('btn-large')
	end

	if not self.link then
		return tostring(button)
	end
	-- Have to wrap it in an extra div to prevent the mediawiki parser from messing it up
	return tostring(Div{children = {Link{
		link = self.link,
		linktype = self.linktype,
		children = {button}
	}}})
end

return Button
