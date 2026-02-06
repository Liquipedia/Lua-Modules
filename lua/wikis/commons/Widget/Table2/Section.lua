---
-- @Liquipedia
-- page=Module:Widget/Table2/Section
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local WidgetContext = Lua.import('Module:Widget/Context')

---@alias Table2SectionName 'head'|'body'|'foot'

---@class Table2Section: WidgetContext
---@operator call(table): Table2Section
local Table2Section = Class.new(WidgetContext)

---@param default any
---@return Table2SectionName|any
function Table2Section:getValue(default)
	return self.props.value or default
end

---@return Widget
function Table2Section:render()
	local section = self:getValue('body')
	if section == 'head' then
		return HtmlWidgets.Thead{children = self.props.children}
	elseif section == 'foot' then
		return HtmlWidgets.Tfoot{children = self.props.children}
	end
	return HtmlWidgets.Tbody{children = self.props.children}
end

return Table2Section
