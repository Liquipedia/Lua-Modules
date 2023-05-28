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
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local REGION_DATA = mw.loadData('Module:Region/Data')
local COUNTRY_TO_REGION_DATA = Lua.loadDataIfExists('Module:Region/CountryData') or {}

local NO_ENTRY_FOUND_CATEGORY = 'Pages using unsupported region values'

---@param args {region: string?, country: string?, onlyDisplay: boolean?, onlyRegion: boolean?}
---@return string|table
function Region.run(args)
	args = args or {}

	if Logic.readBool(args.onlyRegion) then
		return Region.name(args)
	elseif Logic.readBool(args.onlyDisplay) then
		return Region.display(args)
	end

	return Region.runNew(args)
end

---Retrieves the name of a region as well as the display for it.
---@param args {region: string?, country: string?}
---@return {display: string, region: string?}
function Region.runNew(args)
	local regionValues = Region._raw(args)

	return {
		display = Region._toDisplay(regionValues),
		region = regionValues.region or regionValues.input
	}
end

---Builds the display for a region.
---@param args {region: string?, country: string?}
---@return string
function Region.display(args)
	return Region._toDisplay(Region._raw(args))
end

---Retrieves the name for a region.
---@param args {region: string?, country: string?}
---@return string
function Region.name(args)
	return Region._raw(args).region or ''
end

---Fetches the (raw) data for a region
---@param args {region: string?, country: string?}
---@return {region: string?, flag: string?, file: string?, input: string?}
function Region._raw(args)
	args = args or {}
	local regionInput = args.region

	--determine region from country if region is empty
	if String.isEmpty(regionInput) then
		local country = Flag.CountryName(args.country) or ''
		regionInput = COUNTRY_TO_REGION_DATA[string.lower(country)]
		if String.isEmpty(regionInput) then
			return {}
		end
	end
	---@cast region -nil

	--resolve aliases for the region
	local region = string.lower(regionInput)
	region = REGION_DATA.aliases[region] or region

	return Table.merge(REGION_DATA[region] or {}, {input = regionInput})
end

---Builds the display of a region from its (raw) data
---@param regionValues {region: string?, flag: string?, file: string?, input: string?}
---@return string
function Region._toDisplay(regionValues)
	if Table.isEmpty(regionValues) then
		return ''
	end

	local display = ''
	if regionValues.flag then
		display = Flag.Icon({flag = regionValues.flag, shouldLink = true})
		if display then
			display = display .. '&nbsp;'
		else
			display = ''
		end
	elseif regionValues.file then
		display = '[[File:' .. regionValues.file .. ']]&nbsp;'
	end

	if not regionValues.region then
		mw.ext.TeamLiquidIntegration.add_category(NO_ENTRY_FOUND_CATEGORY)
	end

	return display .. (regionValues.region or regionValues.input)
end

return Class.export(Region, {frameOnly = true})
