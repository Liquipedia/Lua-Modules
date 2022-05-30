---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Series = require('Module:Infobox/Series')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Chronology = require('Module:Infobox/Widget/Chronology')

local CustomSeries = {}

local CustomInjector = Class.new(Injector)

local _args

function CustomSeries.run(frame)
	local series = Series(frame)
	_args = series.args
	series.createWidgetInjector = CustomSeries.createWidgetInjector

	return series:createInfobox(frame)
end

function CustomSeries:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'location' then
		local locations = {}
		_args.country1, _args.city1, _args.location1date = _args.country, _args.city, _args.locationdate
		for _, country, index in Table.iter.pairsByPrefix(_args, 'country') do
			local city = _args['city'.. index]
			local locationDate = _args['location'..index..'date']
			local text = Flags.Icon{flag = country, shouldLink = true} .. '&nbsp;' .. (city or country)
			if locationDate then
				text = text .. '&nbsp;<small>' .. locationDate .. '</small>'
			end
			table.insert(locations, text)
		end
		return { Cell{name = 'Location', content = locations} }
	elseif id == 'customcontent' then
		if String.isNotEmpty(_args.previous) or String.isNotEmpty(_args.next) then
			return {
				Title{name = 'Chronology'},
				Chronology{
					content = {
						previous = _args.previous,
						next = _args.next,
					}
				}
			}
		end
	end
	return widgets
end

return CustomSeries
