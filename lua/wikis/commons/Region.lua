---
-- @Liquipedia
-- page=Module:Region
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Region = {}
local Class = Lua.import('Module:Class')
local Flag = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local REGION_DATA = Lua.import('Module:Region/Data', {loadData = true})
local COUNTRY_TO_REGION_DATA = Lua.requireIfExists('Module:Region/CountryData', {loadData = true}) or {}

local NO_ENTRY_FOUND_CATEGORY = 'Pages using unsupported region values'

---Retrieves the name of a region as well as the display for it.
---@param args {region: string?, country: string?, linkToCategory: boolean?}?
---@return {display: string?, region: string?}
function Region.run(args)
	local regionValues = Region._raw(args)

	return {
		display = Region._toDisplay(regionValues, {linkToCategory = Logic.readBool((args or {}).linkToCategory)}),
		region = regionValues.region or regionValues.input
	}
end

---Builds the display for a region.
---@param args {region: string?, country: string?, linkToCategory: boolean?}?
---@return string
function Region.display(args)
	return Region._toDisplay(Region._raw(args), {linkToCategory = Logic.readBool((args or {}).linkToCategory)}) or ''
end

---Retrieves the name for a region.
---@param args {region: string?, country: string?, linkToCategory: boolean?}?
---@return string
function Region.name(args)
	return Region._raw(args).region or ''
end

---Fetches the (raw) data for a region
---@param args {region: string?, country: string?, linkToCategory: boolean?}?
---@return {region: string?, flag: string?, file: string?, input: string?}
function Region._raw(args)
	args = args or {}
	local regionInput = args.region

	--determine region from country if region is empty
	if String.isEmpty(regionInput) then
		local country = Flag.CountryName{flag = args.country} or ''
		regionInput = COUNTRY_TO_REGION_DATA[string.lower(country)]
		if String.isEmpty(regionInput) then
			return {}
		end
	end
	---@cast regionInput -nil

	--resolve aliases for the region
	local region = string.lower(regionInput)
	region = REGION_DATA.aliases[region] or region

	return Table.merge(REGION_DATA[region] or {}, {input = regionInput})
end

---Builds the display of a region from its (raw) data
---@param regionValues {region: string?, flag: string?, file: string?, input: string?}
---@param options {linkToCategory: boolean?}?
---@return string?
function Region._toDisplay(regionValues, options)
	if Table.isEmpty(regionValues) then
		return
	end

	options = options or {}

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

	local text = regionValues.region or regionValues.input

	if not options.linkToCategory then
		return display .. text
	end

	return display .. Page.makeInternalLink({}, text, ':Category:' .. text)
end

return Class.export(Region, {frameOnly = true, exports = {'run', 'display', 'name'}})
