---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Series = require('Module:Infobox/Series')

local CustomSeries = {}

function CustomSeries.run(frame)
	local series = Series(frame)
	return series:createInfobox(frame)
end

return CustomSeries
