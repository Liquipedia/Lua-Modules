---
-- @Liquipedia
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Series = Lua.import('Module:Infobox/Series')

---@class CustomSeriesInfobox: SeriesInfobox
local CustomSeries = Class.new(Series)

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = CustomSeries(frame)
	return series:createInfobox()
end

return CustomSeries
