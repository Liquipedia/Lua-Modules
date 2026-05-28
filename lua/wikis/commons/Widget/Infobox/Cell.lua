---
-- @Liquipedia
-- page=Module:Widget/Infobox/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local CollapsibleToggle = Lua.import('Module:Widget/GeneralCollapsible/Toggle')
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local Html = Lua.import('Module:Widget/Html')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class CellWidgetOptions
---@field collapsible boolean?
---@field columns number?
---@field makeLink boolean?
---@field suppressColon boolean?
---@field separator Renderable?

---@class CellWidgetProps
---@field name Renderable
---@field classes string[]?
---@field children Renderable[]
---@field options CellWidgetOptions?

local Cell = {}
---@type CellWidgetOptions
Cell.defaultOptions = {
	collapsible = false,
	columns = 2,
	makeLink = false,
	suppressColon = false,
	separator = '<br />',
}

---@param props CellWidgetProps
---@return Widget?
function Cell.render(props)
	local name = assert(Logic.nilIfEmpty(props.name))
	local children = props.children
	if Logic.isEmpty(children) then
		return
	end

	---@type CellWidgetOptions
	local options = setmetatable(props.options or {}, {__index = Cell.defaultOptions})

	local mappedChildren = Array.map(props.children, function(child)
		if options.makeLink then
			---@cast child string
			return Link{children = {child}, link = child}
		else
			return child
		end
	end)

	if Logic.isEmpty(mappedChildren[1]) then
		return
	end

	return Html.Div{
		classes = props.classes,
		children = {
			Html.Div{
				classes = {'infobox-cell-' .. options.columns, 'infobox-description'},
				children = {name, not options.suppressColon and ':' or nil}
			},
			Cell._buildChildrenContainer(mappedChildren, options)
		}
	}
end

---@private
---@param mappedChildren Renderable[]
---@return Widget
function Cell._buildChildrenContainer(mappedChildren, options)
	local widgetProps = {
		css = {width = (100 * (options.columns - 1) / options.columns) .. '%'}, -- 66.66% for col = 3
		children = Array.interleave(mappedChildren, options.separator)
	}

	if not options.collapsible then
		return Html.Div(widgetProps)
	end

	widgetProps.shouldCollapse = true
	widgetProps.titleWidget = CollapsibleToggle{
		showButtonChildren = {
			'Expand',
			' ',
			Icon{iconName = 'expand'}
		},
		hideButtonChildren = {
			'Collapse',
			' ',
			Icon{iconName = 'collapse'}
		}
	}

	return GeneralCollapsible(widgetProps)
end

return Component.component(Cell.render)
