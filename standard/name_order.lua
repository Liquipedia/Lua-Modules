---
-- @Liquipedia
-- wiki=commons
-- page=Module:NameOrder
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

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
For countries using the eastern order, (familyName, givenName) is returned whereas
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
		return familyName, givenName
	end
end

return Class.export(NameOrder)
