---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Customizable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')
local Injector = require('Module:Infobox/Widget/Injector')

local Customizable = Class.new(
	Widget,
	function(self, input)
		self.id = self:assertExistsAndCopy(input.id)
		self.children = input.children
	end
)

function Customizable:setWidgetInjector(injector)
	if injector == nil then
		return
	elseif injector['is_a'] == nil or injector:is_a(Injector) == false then
		return error('Valid Injector from Infobox/Widget/Injector needs to be provided')
	end
	self.injector = injector
end

function Customizable:make()
	if self.injector == nil then
		return self.children
	end
	if self.id == ' custom' then
		return self.injector:addCustomCells(self.children)
	end
	return self.injector:parse(self.id, self.children)
end

return Customizable
