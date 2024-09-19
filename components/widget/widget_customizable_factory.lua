---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Customizable/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Customizable = Lua.import('Module:Widget/Customizable')

local CustomizableFactory = {}

---@param injector WidgetInjector?
---@return fun(props: {id: string, children: Widget[]}): CustomizableWidget
function CustomizableFactory.createCustomizable(injector)
	return function(props)
		return Customizable{
			id = props.id,
			children = props.children,
			injector = injector,
		}
	end
end

return CustomizableFactory
