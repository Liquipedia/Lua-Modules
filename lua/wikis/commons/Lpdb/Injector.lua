---
-- @Liquipedia
-- page=Module:Lpdb/Injector
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

--- @class LpdbInjector: BaseClass
local Injector = Class.new()

function Injector:adjust(lpdbData, ...)
	return lpdbData
end

return Injector
