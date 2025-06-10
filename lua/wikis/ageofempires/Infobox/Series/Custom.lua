---
-- @Liquipedia
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Tier = require('Module:Tier/Custom')

local Series = Lua.import('Module:Infobox/Series')

---@class AoeSeriesInfobox: SeriesInfobox
local CustomSeries = Class.new(Series)

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = CustomSeries(frame)

	return series:createInfobox()
end

---@param args table
---@return string
function CustomSeries:createLiquipediaTierDisplay(args)
	return (Tier.display(
		args.liquipediatier,
		args.liquipediatiertype
	) or '') .. self:appendLiquipediatierDisplay(args)
end

return CustomSeries
