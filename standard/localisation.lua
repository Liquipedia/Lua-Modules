---
-- @Liquipedia
-- wiki=commons
-- page=Module:Localisation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Localisation = {}
local String = require('Module:StringUtils')
local Logic = require('Module:Logic')

function Localisation.getCountryName(country, noentry)
	local data = mw.loadData('Module:Localisation/data/country')

	-- clean the entered country value
	country = Localisation._cleanCountry(country)

	-- First try to look it up
	local countryname = data[country]

	-- Return message if none is found
	if countryname == nil then
		mw.log('No country found in Module:Localisation/data/country: ' .. country)
		-- set category unless second argument is set
		if noentry ~= '' then
			countryname = ''
		else
			countryname = mw.getCurrentFrame()
				:expandTemplate{title = 'Flag/invalidcountry', args = {country}}
		end
	end

	return countryname
end

-- use Module:Flags instead
---@deprecated
function Localisation.getLocalisation(options, country)
	--in case no options are entered the country is the first var
	--so we need to adjust for that
	--in that case it will be a string so we catch it via this
	--it also catches cases where country and options are switched
	if type(options) == 'string' then
		local tempForSwitch = country
		country = options
		options = tempForSwitch
	end

	--avoid indexing nil
	options = options or {}

	local displayNoError = Logic.readBool(options.displayNoError)
	local shouldReturnSimpleError = Logic.readBool(options.shouldReturnSimpleError)

	local dataModuleName = 'Module:Localisation/data/localised'
	local data = mw.loadData(dataModuleName)

	-- clean the entered country value
	country = Localisation._cleanCountry(country)

	-- First try to look it up
	local localised = data[country]

	-- Return message if none is found
	if localised == nil then
		mw.log('No country found in ' .. dataModuleName .. ': ' .. country)
		-- set category unless second argument is set
		if displayNoError then
			localised = ''
		elseif shouldReturnSimpleError then
			localised = 'error'
		else
			localised = 'Unknown country "[[lpcommons:' .. dataModuleName ..
				'|' .. country .. ']][[Category:Pages with unknown countries]]'
		end
	end

	return localised
end

function Localisation._cleanCountry(country)
	if String.isEmpty(country) then
		country = 'nocountry'
	end
	-- Remove whitespace
	country = mw.text.trim(country)
	country = mw.text.unstripNoWiki(country)
	country = string.upper(country)

	return country
end

return Class.export(Localisation, {frameOnly = true})
