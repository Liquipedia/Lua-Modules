---
-- @Liquipedia
-- page=Module:Widget/Basic/Button
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local Div = Html.Div

---@class ButtonWidgetProps: HtmlNodeProps
---@field title string?
---@field link string?
---@field linktype 'internal'|'external'|nil
---@field variant 'primary'|'secondary'|'themed'|'ghost'|'destructive'|'icon'|nil
---@field size 'xs'|'sm'|'md'|'lg'|nil
---@field grow boolean?
---@field aligncontent 'left'|'right'|nil

local defaultProps = {
	linktype = 'internal',
	variant = 'primary',
	size = 'md',
	grow = false, -- Whether the button should grow to fill the available space
	aligncontent = nil,
}

---@param props ButtonWidgetProps
---@return HtmlNode
local function Button(props)
	--- MW Parser does not allowed the <button> tag, so we use a <div>
	local cssClasses = {'button'}
	if props.variant == 'primary' then
		table.insert(cssClasses, 'button--primary')
	elseif props.variant == 'secondary' then
		table.insert(cssClasses, 'button--secondary')
	elseif props.variant == 'themed' then
		table.insert(cssClasses, 'button--themed')
	elseif props.variant == 'ghost' then
		table.insert(cssClasses, 'button--ghost')
	elseif props.variant == 'destructive' then
		table.insert(cssClasses, 'button--destructive')
	end

	if props.size == 'xs' then
		table.insert(cssClasses, 'button--extrasmall')
	elseif props.size == 'sm' then
		table.insert(cssClasses, 'button--small')
	elseif props.size == 'lg' then
		table.insert(cssClasses, 'button--large')
	end

	local cssTable = {}
	if props.grow then
		cssTable.width = '100%'
	end
	if props.aligncontent == 'left' then
		cssTable['justify-content'] = 'left'
	elseif props.aligncontent == 'right' then
		cssTable['justify-content'] = 'right'
	end

	local button = Div{
		css = Logic.nilIfEmpty(cssTable),
		classes = Array.extend(cssClasses, props.classes or {}),
		attributes = Table.merge({
			title = props.title,
			['aria-label'] = props.title,
			role = 'button',
			tabindex = '0',
		}, props.attributes or {}),
		children = props.children,
	}

	if not props.link then
		return button
	end

	-- Have to wrap it in an extra div to prevent the mediawiki parser from messing it up
	return Div{
		css = props.grow and {flex = '1'} or nil,
		classes = props.classes or {},
		children = {
			Link{
				link = props.link,
				linktype = props.linktype,
				children = {button},
			}
		}
	}
end

return Component.component(Button, defaultProps)
