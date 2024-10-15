---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')

---@class WidgetHtmlBase: Widget
---@operator call(table): WidgetHtmlBase
local HtmlBase = Class.new(Widget)
HtmlBase.defaultProps = {
	classes = {},
	css = {},
	attributes = {},
}

---@return Html
function HtmlBase:render()
	error('HtmlBase:render() must be overridden')
end

---@param tag string?
---@param children (Widget|Html|string|number)[]
---@param attributesInput {style: table, class: table, [string]: string}
---@return Html
function HtmlBase:renderAs(tag, children, attributesInput)
	local htmlNode = mw.html.create(tag)

	---@type table<string, string|table>
	local attributes = Table.copy(attributesInput)
	local class = Table.extract(attributes, 'class') --[[@as table]]
	local styles = Table.extract(attributes, 'style') --[[@as table]]
	---@cast attributes table<string, string>

	htmlNode:addClass(String.nilIfEmpty(table.concat(class, ' ')))
	htmlNode:css(styles)

	htmlNode:css(styles)
	htmlNode:attr(attributes)

	Array.forEach(children, function(child)
		if Class.instanceOf(child, Widget) then
			---@cast child Widget
			child.context = self:_nextContext()
			htmlNode:node(child:tryMake())
		else
			---@cast child -Widget
			---@diagnostic disable-next-line: undefined-field
			if type(child) == 'table' and not child._build then
				mw.log('ERROR! Bad child input:' .. mw.dumpObject(self.props.children))
				-- Erroring here to make it easier to debug
				-- Otherwise it will fail when the html is built
				error('Table passed to HtmlBase:renderAs() without _build method')
			end
			htmlNode:node(child)
		end
	end)
	return htmlNode
end

return HtmlBase
