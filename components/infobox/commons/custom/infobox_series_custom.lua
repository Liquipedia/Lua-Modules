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

function CustomSeries.run(frame)
	local series = Series(frame)
	return series:createInfobox(frame)
end

return CustomSeries
