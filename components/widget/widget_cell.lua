---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class CellWidgetOptions
---@field columns number?
---@field makeLink boolean?
---@field surpressColon boolean?

---@class CellWidget: Widget
---@operator call({name:string|number,content:(string|number)[],classes:string[]?,options:CellWidgetOptions}):CellWidget
---@field name string|number
---@field children (string|number)[]
---@field options CellWidgetOptions
---@field classes string[]?
local Cell = Class.new(Widget,
	function(self, input)
		self.name = self:assertExistsAndCopy(input.name)
		self.children = input.children or input.content or {}
		self.options = input.options or {}
		self.classes = input.classes

		self.options.columns = self.options.columns or 2
	end
)

---@param description string|number
---@return CellWidget
function Cell:_new(description)
	self.root = mw.html.create('div')
	self.description = mw.html.create('div')
	self.description:addClass('infobox-cell-'.. self.options.columns)
					:addClass('infobox-description')
					:wikitext(description)
					:wikitext(not self.options.surpressColon and ':' or nil)
	self.contentDiv = nil
	return self
end

---@param ... string
---@return CellWidget
function Cell:_class(...)
	for i = 1, select('#', ...) do
		local item = select(i, ...)
		if item == nil then
			break
		end

		self.root:addClass(item)
	end
	return self
end

---@param ... string
---@return CellWidget
function Cell:_content(...)
	local firstItem = select(1, ...)
	if firstItem == nil or firstItem == '' then
		self.contentDiv = nil
		return self
	end

	self.contentDiv = mw.html.create('div')
	self.contentDiv:css('width', (100 * (self.options.columns - 1) / self.options.columns) .. '%') -- 66.66% for col = 3
	for i = 1, select('#', ...) do
		if i > 1 then
			self.contentDiv:wikitext('<br/>')
		end
		local item = select(i, ...) ---@type string?
		if item == nil then
			break
		end

		if self.options.makeLink == true then
			self.contentDiv:wikitext('[[' .. item .. ']]')
		else
			self.contentDiv:wikitext(item)
		end
	end
	return self
end

---@param injector WidgetInjector?
---@param children string[]
---@return string?
function Cell:make(injector, children)
	self:_new(self.name)
	self:_class(unpack(self.classes or {}))
	self:_content(unpack(children))

	if self.contentDiv == nil then
		return
	end

	self.root	:node(self.description)
				:node(self.contentDiv)
	return tostring(self.root)
end

return Cell
