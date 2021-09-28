---
-- @Liquipedia
-- wiki=commons
-- page=Module:Region
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local region = {}
local Class = require('Module:Class')
local Flag = require('Module:Flags')
local String = require('Module:String')
local Lua = require('Module:Lua')
local regionData = mw.loadData('Module:Region/Data')
local countryToRegionData = Lua.loadDataIfExists('Module:Region/CountryData', {})

function region.run(args)
	args = args or {}
	local regionEntry = args.region
	local onlyRegion = args.onlyRegion == 'true'
	local onlyDisplay = args.onlyDisplay == 'true'

	if String.isEmpty(regionEntry) then
		local country = Flag._CountryName(args.country)
		regionEntry = countryToRegionData[string.lower(country)]
		if String.isEmpty(regionEntry) then
			return ''
		end
	end

	regionEntry = string.lower(regionEntry)
	regionEntry = regionData.aliases[regionEntry] or regionEntry
	local regionReturn = regionData[regionEntry] or {}
	if onlyRegion then
		return regionReturn.region or ''
	elseif regionReturn ~= {} then
		local display = ''
		if regionReturn.flag then
			display = Flag._Flag(regionReturn.flag)
			if display then
				display = display .. '&nbsp;'
			else
				display = ''
			end
		elseif regionReturn.file then
			display = '[[File:' .. regionReturn.file .. ']]&nbsp;'
		end
		if onlyDisplay then
			return display .. regionReturn.region
		else
			return {
				display = display .. regionReturn.region,
				region = regionReturn.region
			}
		end
	end
	return regionReturn
end

return Class.export(region, {frameOnly = true})
