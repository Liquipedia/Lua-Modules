---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Cell = require('Module:Infobox/Widget/Cell')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Tier = require('Module:Tier/Custom')

local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Series = Lua.import('Module:Infobox/Series', {requireDevIfEnabled = true})

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
