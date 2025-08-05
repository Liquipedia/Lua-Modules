---
-- @Liquipedia
-- page=Module:Locale
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local Operator = Lua.import('Module:Operator')
local Region = Lua.import('Module:Region')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

-- ISO 3166-1 alpha-2 Exceptional Reservations
local EXCEPTIONAL_RESERVATIONS = {'eu', 'un'}

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

---@param args table
---@return table
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

		-- Keep unresolved country as it might be a region instead
		local unresolvedCountry = location.country
		-- Convert country to alpha2
		if location.country then
			location.country = String.nilIfEmpty(Flags.CountryCode{flag = location.country})
		end

		-- Remove country if it is actually a region
		if Array.find(EXCEPTIONAL_RESERVATIONS, FnUtil.curry(Operator.eq, location.country)) then
			location.country = nil
		end

		-- Always normalize region name
		if not location.region and unresolvedCountry then
			-- Check if the country provided is actually a region
			location.region = String.nilIfEmpty(Region.name{region = unresolvedCountry})

			-- Get the Region from the country if still unknown
			if not location.region then
				location.region = String.nilIfEmpty(Region.name{country = location.country})
			end
		elseif location.region then
			location.region = String.nilIfEmpty(Region.name{region = location.region})
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


return Class.export(Locale, {frameOnly = true, exports = {'formatLocation', 'formatLocations'}})
