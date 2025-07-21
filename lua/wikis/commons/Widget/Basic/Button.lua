---
-- @Liquipedia
-- page=Module:Widget/Basic/Button
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Div = HtmlWidgets.Div

---@class ButtonWidgetParameters
---@field title string?
---@field link string?
---@field linktype 'internal'|'external'|nil
---@field variant 'primary'|'secondary'|'tertiary'|'ghost'|'destructive'|nil
---@field size 'xs'|'sm'|'md'|'lg'|nil
---@field grow boolean?

---@class ButtonWidget: Widget
---@operator call(ButtonWidgetParameters): ButtonWidget

local Button = Class.new(Widget)
Button.defaultProps = {
	linktype = 'internal',
	variant = 'primary',
	size = 'md',
	grow = false, -- Whether the button should grow to fill the available space
}

---@return Widget
function Button:render()
	--- MW Parser does not allowed the <button> tag, so we use a <div>
	local cssClasses = {'btn'}
	if self.props.variant == 'primary' then
		table.insert(cssClasses, 'btn-primary')
	elseif self.props.variant == 'secondary' then
		table.insert(cssClasses, 'btn-secondary')
	elseif self.props.variant == 'tertiary' then
		table.insert(cssClasses, 'btn-tertiary')
	elseif self.props.variant == 'ghost' then
		table.insert(cssClasses, 'btn-ghost')
	elseif self.props.variant == 'destructive' then
		table.insert(cssClasses, 'btn-destructive')
	end

	if self.props.size == 'xs' then
		table.insert(cssClasses, 'btn-extrasmall')
	elseif self.props.size == 'sm' then
		table.insert(cssClasses, 'btn-small')
	elseif self.props.size == 'lg' then
		table.insert(cssClasses, 'btn-large')
	end

	local button = Div{
		css = self.props.grow and {width = '100%'} or nil,
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
	return Div{
		css = self.props.grow and {flex = '1'} or nil,
		classes = self.props.classes or {},
		children = {
			Link{
				link = self.props.link,
				linktype = self.props.linktype,
				children = {button},
			}
		}
	}
end

return Button
