---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Series = Lua.import('Module:Infobox/Series', {requireDevIfEnabled = true})

local CustomSeries = {}

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = Series(frame)
	return series:createInfobox()
end

return CustomSeries
