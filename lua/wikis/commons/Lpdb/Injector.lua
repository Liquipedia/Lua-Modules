---
-- @Liquipedia
-- page=Module:Lpdb/Injector
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

--- @class LpdbInjector: BaseClass
local Injector = Class.new()

function Injector:adjust(lpdbData, ...)
	return lpdbData
end

return Injector
