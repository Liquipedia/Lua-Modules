---
-- @Liquipedia
-- page=Module:Widget/Builder
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')

---@generic T
---@param props {builder: fun(): T?}
---@return T?
local function Builder(props)
	return props.builder()
end

return Component.component(Builder)
