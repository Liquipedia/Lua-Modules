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

---@class ButtonWidgetParameters: WidgetParameters
---@field title string
---@field link string?
---@field variant 'primary'|'secondary'|'ghost'|nil
---@field size 'sn'|'md'|'lg'|nil

---@class ButtonWidget: Widget
---@operator call(ButtonWidgetParameters): ButtonWidget
---@field title string
---@field link string?
---@field variant 'primary'|'secondary'|'ghost'
---@field size 'sn'|'md'|'lg'

local Button = Class.new(
	Widget,
	function(self, input)
		self.title = self:assertExistsAndCopy(input.title)
		self.link = input.link
		self.variant = input.variant or 'primary' -- TODO: Validate
		self.size = input.size or 'md' -- TODO: Validate
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

	if self.size == 'sn' then
		button:addClass('small')
	elseif self.size == 'md' then
		button:addClass('medium')
	elseif self.size == 'lg' then
		button:addClass('large')
	end

	if not self.link then
		return tostring(button)
	end
	return '[[' .. self.link .. '|'.. tostring(button) .. ']]'
end

return Button
