---
-- @Liquipedia
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Series = Lua.import('Module:Infobox/Series')
local Flags = Lua.import('Module:Flags')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class DotaSeriesInfobox: SeriesInfobox
local CustomSeries = Class.new(Series)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = CustomSeries(frame)
	series:setWidgetInjector(CustomInjector(series))

	return series:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'location' then
		local locations = {}
		args.city1 = args.city1 or args.city
		for prefix, country, index in Table.iter.pairsByPrefix(args, 'country', {requireIndex = false}) do
			local city = args['city'.. index]
			local locationDate = args[prefix..'date']
			local text = Flags.Icon{flag = country, shouldLink = true} .. '&nbsp;' .. (city or country)
			if locationDate then
				text = text .. '&nbsp;<small>' .. locationDate .. '</small>'
			end
			table.insert(locations, text)
		end
		return {Cell{name = 'Location', content = locations}}
	end
	return widgets
end

return CustomSeries
