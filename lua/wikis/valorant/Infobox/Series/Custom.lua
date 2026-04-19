---
-- @Liquipedia
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Table = Lua.import('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Series = Lua.import('Module:Infobox/Series')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Chronology = Widgets.Chronology

---@class ValorantSeriesInfobox: SeriesInfobox
---@operator call(Frame): ValorantSeriesInfobox
local CustomSeries = Class.new(Series)

---@class ValorantSeriesInfoboxWidgetInjector: WidgetInjector
---@field caller ValorantSeriesInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
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
		return { Cell{name = 'Location', children = locations} }
	elseif id == 'customcontent' then
		return {
			Chronology{args = args, showTitle = true}
		}
	end
	return widgets
end

return CustomSeries
