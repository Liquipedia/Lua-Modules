---
-- @Liquipedia
-- page=Module:Widget/Table2/TableBody
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Context = Lua.import('Module:Widget/ComponentContext')

local Table2Contexts = Lua.import('Module:Widget/Contexts/Table2')

---@class Table2BodyProps
---@field children? Renderable|Renderable[]

---@param props Table2BodyProps
---@return Renderable
local function Table2Body(props)
	return Context.Provider{
		def = Table2Contexts.Section,
		value = 'body',
		children = props.children or {},
	}
end

return Component.component(
	Table2Body
)
