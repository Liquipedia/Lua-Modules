---
-- @Liquipedia
-- page=Module:Features/DurationStats/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Controller = Lua.import('Module:Features/DurationStats/Controller')

local CustomDurationStats = {}

---@param frame Frame
---@return Widget
function CustomDurationStats.run(frame)
	return Controller.run(frame)
end

return CustomDurationStats
