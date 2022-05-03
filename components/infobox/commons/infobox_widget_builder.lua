---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Builder
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')
local WidgetFactory = require('Module:Infobox/Widget/Factory')

local Builder = Class.new(
	Widget,
	function(self, input)
		self.builder = input.builder
	end
)

function Builder:make()
	local children = self.builder()
	local widgets = {}
	for _, child in ipairs(children or {}) do
		local childOutput = WidgetFactory.work(child, self.context.injector)
		-- Our child might contain a list of children, so we need to iterate
		for _, item in ipairs(childOutput) do
			table.insert(widgets, item)
		end
	end
	return widgets
end

return Builder
