---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Customizable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')

local Customizable = Class.new(
	Widget,
	function(self, input)
		self.id = self:assertExistsAndCopy(input.id)
		self.children = input.children
	end
)

function Customizable:_make()
	if self.context.injector == nil then
		return self.children
	end
	if self.id == 'custom' then
		return self.context.injector:addCustomCells(self.children)
	end
	return self.context.injector:parse(self.id, self.children)
end

return Customizable
