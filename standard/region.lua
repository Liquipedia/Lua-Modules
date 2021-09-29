---
-- @Liquipedia
-- wiki=commons
-- page=Module:Region
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Region = {}
local Class = require('Module:Class')
local Flag = require('Module:Flags')
local String = require('Module:String')
local Lua = require('Module:Lua')
local regionData = mw.loadData('Module:Region/Data')
local countryToRegionData = Lua.loadDataIfExists('Module:Region/CountryData', {})

local noEntryFoundCategory = '[[Category:Pages using unsupported region values]]'

function Region.run(args)
	args = args or {}
	local region = args.region
	local shouldOnlyReturnRegionName = args.onlyRegion == 'true'
	local shouldOnlyReturnDisplay = args.onlyDisplay == 'true'

	--determine region from country if region is empty
	if String.isEmpty(region) then
		local country = Flag._CountryName(args.country) or ''
		region = countryToRegionData[string.lower(country)]
		if String.isEmpty(region) then
			return ''
		end
	end

	--resolve aliases for the region
	region = string.lower(region)
	region = regionData.aliases[region] or region

	local regionValues = regionData[region] or {region = args.region .. noEntryFoundCategory}
	if shouldOnlyReturnRegionName then
		return regionValues.region
	else
		local display = ''
		if regionValues.flag then
			display = Flag._Flag(regionValues.flag)
			if display then
				display = display .. '&nbsp;'
			else
				display = ''
			end
		elseif regionValues.file then
			display = '[[File:' .. regionValues.file .. ']]&nbsp;'
		end
		if shouldOnlyReturnDisplay then
			return display .. regionValues.region
		else
			return {
				display = display .. regionValues.region,
				region = regionValues.region
			}
		end
	end
	return regionValues
end

return Class.export(Region, {frameOnly = true})
