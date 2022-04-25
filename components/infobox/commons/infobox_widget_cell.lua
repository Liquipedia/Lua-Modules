---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local IsolatedWidget = require('Module:Infobox/IsolatedWidget')

local Cell = Class.new(IsolatedWidget,
	function(self, input)
		self.name = self:assertExistsAndCopy(input.name)
		self.content = input.content
		self.options = input.options
		self.classes = input.classes
	end
)

function Cell:_new(description)
	self.root = mw.html.create('div')
	self.description = mw.html.create('div')
	self.description:addClass('infobox-cell-2')
					:addClass('infobox-description')
					:wikitext(description .. ':')
	self.contentDiv = nil
	return self
end

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

function Cell:_content(...)
	self.contentText = ...
	local firstItem = select(1, ...)
	if firstItem == nil or firstItem == '' then
		self.contentDiv = nil
		return self
	end

	self.contentDiv = mw.html.create('div')
	self.contentDiv:addClass('infobox-cell-2')
	for i = 1, select('#', ...) do
		if i > 1 then
			self.contentDiv:wikitext('<br/>')
		end
		local item = select(i, ...)
		if item == nil then
			break
		end

		if self.options ~= nil and self.options.makeLink == true then
			self.contentDiv:wikitext('[[' .. item .. ']]')
		else
			self.contentDiv:wikitext(item)
		end
	end
	return self
end

function Cell:create()
	self:_new(self.name)
	self:_class(unpack(self.classes or {}))
	self:_content(unpack(self.content))

	if self.contentDiv == nil then
		return {}
	end

	self.root	:node(self.description)
				:node(self.contentDiv)
	return {
		self.root
	}
end

return Cell
