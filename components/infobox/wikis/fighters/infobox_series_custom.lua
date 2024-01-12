---
-- @Liquipedia
-- wiki=fighters
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Series = Lua.import('Module:Infobox/Series', {requireDevIfEnabled = true})

local CustomSeries = {}

local _series

function CustomSeries.run(frame)
	_series = Series(frame)

	_series.addToLpdb = CustomSeries.addToLpdb

	return _series:createInfobox()
end

function CustomSeries:addToLpdb(lpdbData)
	lpdbData.extradata = {
		parentseries = _series.args.parentseries
	}

	return lpdbData
end

return CustomSeries
