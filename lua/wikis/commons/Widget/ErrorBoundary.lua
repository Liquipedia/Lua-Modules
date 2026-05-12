---
-- @Liquipedia
-- page=Module:Widget/ErrorBoundary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ComponentCore = Lua.import('Module:Widget/Component')
local Types = Lua.import('Module:Widget/Types')

return setmetatable(
	{ renderFn = Types.ERROR_BOUNDARY },
	ComponentCore.ComponentMT
) --[[@as ErrorBoundaryComponent]]
