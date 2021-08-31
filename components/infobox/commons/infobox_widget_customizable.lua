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
	function(self, id, widgets)
		self.id = self:assertExistsAndCopy(id)
		self.widgets = widgets
	end
)

function Customizable:setWidgetInjector(injector)
	if injector:is_a(Injector) == false then
		return error('Valid Injector from Infobox/Widget/Injector needs to be provided')
	end
	self.injector = injector
end

function Customizable:make()
	return self.injector:parse(self.id, self.widgets)
end

return Customizable
