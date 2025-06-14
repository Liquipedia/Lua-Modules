---
-- @Liquipedia
-- page=Module:Widget/NavBox/Child
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local B = HtmlWidgets.B
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span
local Tr = HtmlWidgets.Tr
local Th = HtmlWidgets.Th

local CollapsibleToggle = Lua.import('Module:Widget/GeneralCollapsible/Toggle')
local EditButton = Lua.import('Module:Widget/NavBox/EditButton')
local Link = Lua.import('Module:Widget/Basic/Link')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class NavBoxTitleProps: NavBoxChildProps
---@field isWrapper boolean?
---@field template string?
---@field colSpan integer?

---@class NavBoxTitle: Widget
---@operator call(table): NavBoxTitle
---@field props NavBoxTitleProps
local NavBoxTitle = Class.new(Widget)
NavBoxTitle.defaultProps = {
	title = 'Click on the "show"/"hide" link on the right to collapse/uncollapse the full list',
}

---@return Widget
function NavBoxTitle:render()
	local props = self.props
	local titleText = self:_getTitleText()

	if self.props.isWrapper then
		return Div{
			classes = {'navbox-title'},
			children = WidgetUtil.collect(
				EditButton{templateLink = self.props.template},
				B{children = titleText},
				CollapsibleToggle{css = {float = 'right'}}
			)
		}
	end

	return Tr{
		children = {
			Th{
				attributes = {colspan = props.colSpan},
				classes = {'navbox-title'},
				children = titleText,
			}
		}
	}
end

---@private
---@return (string|Widget)[]
function NavBoxTitle:_getTitleText()
	local props = self.props
	local titleLink = props.titleLink
	local titleText = titleLink and Link{link = titleLink, children = {props.title}} or props.title
	local mobileTitle = props.mobileTitle and titleLink and Link{link = titleLink, children = {props.mobileTitle}}
		or props.mobileTitle
	return {
		mobileTitle and Span{children = titleText, classes = {'mobile-hide'}} or titleText,
		mobileTitle and Span{children = mobileTitle, classes = {'mobile-only'}} or nil,
	}
end

return NavBoxTitle
