---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/DuoCell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')
local String = require('Module:String')

local DuoCell = Class.new(Widget,
	function(self, input)
		self.content = input.content
	end
)

function DuoCell:_new(content)
	content = content or {}
	if String.isEmpty(content[1]) then
		self.root = nil
	else
		self.root = mw.html.create('div')
		self.content1Div = mw.html.create('div')
		self.content1Div:addClass('infobox-cell-2')
						:wikitext(content[1])
		if not String.isEmpty(content[2]) then
			self.content2Div = mw.html.create('div')
			self.content2Div:addClass('infobox-cell-2')
							:wikitext(content[2])
		end
	end
	return self
end

function DuoCell:make()
	self:_new(self.content)

	if self.content1Div == nil then
		return {}
	end

	self.root:node(self.content1Div)

	if self.content2Div ~= nil then
		self.root:node(self.content2Div)
	end

	return {
		self.root
	}
end

return DuoCell
