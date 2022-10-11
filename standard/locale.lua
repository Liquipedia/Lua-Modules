---
-- @Liquipedia
-- wiki=commons
-- page=Module:Locale
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Region = require('Module:Region')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Locale = {}

---@param args {city: string, country:string}
---@return string
function Locale.formatLocation(args)
	local formattedLocation = ''

	if String.isNotEmpty(args.city) then
		formattedLocation = args.city .. ',&nbsp;'
	end

	formattedLocation = formattedLocation .. (args.country or '')
	return formattedLocation
end

function Locale.formatLocations(args)
	local LOCATION_KEYS = {
		'venue${index}',
		'venue${index}link',
		'city${index}',
		'country${index}',
		'region${index}'
	}
	local locations = Array.mapIndexes(function(index)
		local getLocationData = function(_, rawParameter)
			local parameterIndexless = String.interpolate(rawParameter, {index = ''})
			local parameter = String.interpolate(rawParameter, {index = index})
			return parameterIndexless, args[parameter]
		end

		local location = Table.mapValues(Table.map(LOCATION_KEYS, getLocationData), String.nilIfEmpty)
		if index == 1 then
			local getLocationDataIndexless = function(_, rawParameter)
				local parameterIndexless = String.interpolate(rawParameter, {index = ''})
				return parameterIndexless, location[parameterIndexless] or args[parameterIndexless]
			end

			location = Table.mapValues(Table.map(LOCATION_KEYS, getLocationDataIndexless), String.nilIfEmpty)
		end

		if Table.isEmpty(location) then
			return
		end

		-- Always normalize region name
		if not location.region and location.country then
			-- Check if the country provided is actually a region
			location.region = String.nilIfEmpty(Region.run{region = location.country, onlyRegion = true})

			-- If it actually was a region, it's no longer a country, otherwise get the Region from the country
			if location.region then
				location.country = nil
			else
				location.region = String.nilIfEmpty(Region.run{country = location.country, onlyRegion = true})
			end

		elseif location.region then
			location.region = String.nilIfEmpty(Region.run{region = location.region, onlyRegion = true})
		end

		-- Convert country to alpha2
		if location.country then
			location.country = String.nilIfEmpty(Flags.CountryCode(location.country))
		end

		return location
	end)

	local flattenTable = function (tbl)
		local newTable = {}
		Table.iter.forEachPair(tbl, function (outerKey, innerTable)
			Table.iter.forEachPair(innerTable, function (innerKey, innerValue)
				newTable[innerKey .. outerKey] = innerValue
			end)
		end)
		return newTable
	end

	return flattenTable(locations)
end


return Class.export(Locale, {frameOnly = true})
