---
-- @Liquipedia
-- wiki=commons
-- page=Module:Localisation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:StringUtils')

local Localisation = {}

---@deprecated
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
