---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Builder
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')

local Builder = Class.new(
	Widget,
	function(self, input)
		self.builder = input.builder
	end
)

function Builder:make()
	local children = self.builder()
	local widgets = {}
	for _, child in pairs(children or {}) do
		table.insert(widgets, child:make())
	end
end

return Builder
