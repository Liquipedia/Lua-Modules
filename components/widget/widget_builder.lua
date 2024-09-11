---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Builder
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

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
---@param children string[]
---@return string
function Builder:make(injector, children)
	return table.concat(children)
end

---@param injector WidgetInjector?
---@return Widget[]?
function Builder:makeChildren(injector)
	return self.builder()
end

return Builder
