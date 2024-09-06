---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Builder
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetFactory = Lua.import('Module:Infobox/Widget/Factory')

---@class BuilderWidget: Widget
---@operator call({builder: function}): BuilderWidget
---@field builder fun(): Widget[]
local Builder = Class.new(
	Widget,
	function(self, input)
		self.builder = input.builder
	end
)

---@param injector WidgetInjector?
---@return Widget[]
function Builder:make(injector)
	local children = self.builder()
	local widgets = {}
	for _, child in ipairs(children or {}) do
		Array.extendWith(widgets, WidgetFactory.work(child, injector))
	end
	return widgets
end

return Builder
