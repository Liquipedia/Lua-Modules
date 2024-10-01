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
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')

---@class WidgetHtmlBase: Widget
---@operator call(table): WidgetHtmlBase
local HtmlBase = Class.new(Widget)

---@return Html
function HtmlBase:render()
	error('HtmlBase:render() must be overridden')
end

---@param tag string
---@param children (Widget|Html|string|number)[]
---@param attributesInput {class: table?, style: table?, [string]: string}?
---@return Html
function HtmlBase:renderAs(tag, children, attributesInput)
	local htmlNode = mw.html.create(tag)

	local attributes = Table.copy(attributesInput or {})
	local class = Table.extract(attributes, 'class') or {} --[[@as table]]
	local styles = Table.extract(attributes, 'style') or {} --[[@as table]]
	---@cast attributes {[string]: string}

	htmlNode:addClass(table.concat(class, ' '))
	htmlNode:css(styles)
	htmlNode:attr(attributes)

	Array.forEach(children, function(child)
		if Class.instanceOf(child, Widget) then
			---@cast child Widget
			child.context = self:_nextContext()
			htmlNode:node(child:tryMake())
		else
			---@cast child -Widget
			htmlNode:node(child)
		end
	end)
	return htmlNode
end

return HtmlBase
