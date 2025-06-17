---
-- @Liquipedia
-- page=Module:Widget/NavBox/Child
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Image = Lua.import('Module:Image')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span
local Tbl = HtmlWidgets.Table
local Tr = HtmlWidgets.Tr
local Th = HtmlWidgets.Th
local Td = HtmlWidgets.Td
local Link = Lua.import('Module:Widget/Basic/Link')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local NavBoxList = Lua.import('Module:Widget/NavBox/List')

local EMPTY_CHILD_ERROR = 'Empty child found'

---@class NavBoxChild: Widget
---@operator call(table): NavBoxChild
local NavBoxChild = Class.new(Widget)
NavBoxChild.defaultProps = {
	imagesize = '30px',
	imagelink = '',
	imageleftsize = '30px',
	imageleftlink = '',
	center = false,
}

---@return Widget?
function NavBoxChild:render()
	local props = self.props

	assert(Logic.readBool(props.allowEmpty) or props[1] or props.child1, EMPTY_CHILD_ERROR)

	local listElements = Array.mapIndexes(function(index)
		return props[index]
	end)
	local listCss = {['text-align'] = Logic.readBool(props.center) and 'center' or nil}

	if not props.child1 then
		return NavBoxList{children = listElements, css = listCss}
	end

	local children = Array.mapIndexes(function(rowIndex)
		return NavBoxChild._getChild(props['child' .. rowIndex])
	end)

	if props[1] then
		table.insert(children, {
			name = props.name,
			mobileName = props.mobileName,
			child = NavBoxList{children = listElements, css = listCss}
		})
	end

	self.rowSpan = #children
	self.anyHasName = Array.any(children, function(child)
		return Logic.isNotEmpty(child.name)
	end)

	local colSpan = ((props.imageleft or props.imageleftdark) and 1 or 0)
		+ (self.anyHasName and 1 or 0)
		+ 1 -- middle Row is always shown
		+ ((props.image or props.imagedark) and 1 or 0)

	local shouldCollapse = Logic.readBool(props.collapsed)

	return Tbl{
		classes = {
			'nowraplinks',
			'navbox-inner',
			shouldCollapse and 'collapsible' or nil,
			shouldCollapse and 'collapsed' or nil,
		},
		children = WidgetUtil.collect(
			(props.title or shouldCollapse) and Tr{children = {Th{
				attributes = {colspan = colSpan},
				classes = {'navbox-title'},
				children = {
					props.title and props.titleLink and Link{link = props.titleLink, children = {props.title}} or
						props.title or 'Click on the "show"/"hide" link on the right to collapse/uncollapse the full list'
				},
			}}} or nil,
			Array.map(children, FnUtil.curry(NavBoxChild._toRow, self))
		)
	}
end

---@param childProps table|string?
---@return {name: string?, mobileName: string?, child: Widget}?
function NavBoxChild._getChild(childProps)
	if Logic.isEmpty(childProps) then return end
	if type(childProps) ~= 'table' then
		childProps = Json.parseIfTable(childProps)
	end
	assert(Logic.isNotEmpty(childProps), EMPTY_CHILD_ERROR)
	---@cast childProps -nil

	return {name = childProps.name, mobileName = childProps.mobileName, child = NavBoxChild(childProps)}
end

---@param child {name: string?, mobileName: string?, child: Widget}
---@param childIndex integer
---@return WidgetHtml
function NavBoxChild:_toRow(child, childIndex)
	return Tr{
		children = WidgetUtil.collect(
			self:_makeImage(childIndex, true),
			child.name and Th{
				classes = {'navbox-group'},
				children = {
					child.mobileName and Span{children = child.name, classes = {'mobile-hide'}} or child.name or '',
					child.mobileName and Span{children = child.mobileName, classes = {'mobile-only'}} or nil,
				},
				css = {width = '1%'},
			} or nil,
			Td{
				attributes = {colspan = self.anyHasName and (not child.name) and 2 or nil},
				classes = {'navbox-list', 'hlist-group'},
				css = {padding = 0, width = '100%'},
				children = {child.child},
			},
			self:_makeImage(childIndex, false)
		)
	}
end

---@param childIndex integer
---@param isLeft boolean
---@return Widget?
function NavBoxChild:_makeImage(childIndex, isLeft)
	local props = self.props

	local prefix = 'image' .. (isLeft and 'left' or '')
	local lightMode = props[prefix]
	local darkMode = props[prefix .. 'dark']
	local padding = isLeft and '0 2px 0 0' or '0 0 0 2px'

	if childIndex ~= 1 or not (lightMode or darkMode) then
		return
	end

	return Td{
		attributes = {rowspan = self.rowSpan},
		classes = {'navbox-image'},
		css = {width = '1px', padding = padding},
		children = Div{children = {
			Image.display(
				lightMode,
				darkMode,
				{size = props[prefix .. 'size'], link = props[prefix .. 'link']}
			)
		}}
	}
end

return NavBoxChild
