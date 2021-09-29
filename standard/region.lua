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
		args.region = region
		if String.isEmpty(region) then
			return ''
		end
	end

	--resolve aliases for the region
	region = string.lower(region)
	region = regionData.aliases[region] or region

	local regionValues = regionData[region] or {}
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
		display = display .. (regionValues.region or (args.region .. noEntryFoundCategory))
		if shouldOnlyReturnDisplay then
			return display
		else
			return {
				display = display,
				region = regionValues.region or args.region
			}
		end
	end
end

return Class.export(Region, {frameOnly = true})
