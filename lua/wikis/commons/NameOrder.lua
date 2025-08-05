---
-- @Liquipedia
-- page=Module:NameOrder
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Table = Lua.import('Module:Table')

local NameOrder = {}

local COUNTRIES_EASTERN_NAME_ORDER = {
	'China',
	'Taiwan',
	'Hong Kong',
	'Vietnam',
	'South Korea',
	'Cambodia',
	'Macau',
	'Singapore',
}

---Checks whether the specified country uses Eastern name order
---@param country string?
---@return boolean
function NameOrder.usesEasternNameOrder(country)
	return Table.includes(COUNTRIES_EASTERN_NAME_ORDER, country)
end

--[[
Reorders name as required by the Name Standards.
(familyName, givenName) is returned for countries using the eastern order whereas
(givenName, familyName) is returned for countries using the western order.

User may specify overrides to force/suppress reordering.
]]
---@param givenName string
---@param familyName string
---@param options {country: string?, forceEasternOrder: boolean?, forceWesternOrder: boolean?}
---@return string, string
function NameOrder.reorderNames(givenName, familyName, options)
	if options.forceEasternOrder then
		return familyName, givenName
	elseif options.forceWesternOrder then
		return givenName, familyName
	elseif NameOrder.usesEasternNameOrder(options.country) then
		return familyName, givenName
	else
		return givenName, familyName
	end
end

return NameOrder
