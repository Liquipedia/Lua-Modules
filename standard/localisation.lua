local p = {}
local getArgs = require("Module:Arguments").getArgs

function p.getCountryName(frame)
	local args = getArgs(frame)
	return p._getCountryName(args, frame)
end

function p._getCountryName(args, frame)
	local country = args[1]
	local noentry = args[2] or ''
	local data = mw.loadData('Module:Localisation/data/country')

	if (country == nil) then
		country = 'nocountry'
	end

	-- Remove whitespace
	country = p._cleanCountry(country)

	-- Uppercase
	country = country:upper()

	-- First try to look it up
	local countryname = data[country]

	-- Return message if none is found
	if (countryname == nil) then
		mw.log('No country found in Module:Localisation/data/country: ' .. country)
		-- set category unless second argument is set
		if noentry ~= '' then
			countryname = ''
		else
			countryname = (frame or mw.getCurrentFrame())
				:expandTemplate{title = 'Flag/invalidcountry', args = {country}}
		end
	end

	return countryname
end

-- Get localisation
function p.getLocalisation(frame)
	local args = getArgs(frame)
	return p._getCountryName(args, frame)
end

function p._getLocalisation(args, frame)
	local dataModuleName = 'Module:Localisation/data/localised'
	local country = args[1]
	local noentry = args[2] or ''
	local data = mw.loadData(dataModuleName)

	if (country == nil) then
		country = 'nocountry'
	end

	-- clean the entered country value
	country = p._cleanCountry(country)

	-- Lowercase
	country = country:lower()

	-- First try to look it up
	local localised = data[country]

	-- Return message if none is found
	if (localised == nil) then
		mw.log('No country found in ' .. dataModuleName .. ': ' .. country)
		-- set category unless second argument is set
		if noentry ~= '' then
			localised = ''
		else
			localised = 'Unknown country "[[lpcommons:' .. dataModuleName ..
				'|' .. country .. ']][[Category:Pages with unknown countries]]'
		end
	end

	return localised
end

function p._cleanCountry(country)
	-- Remove whitespace
	country = mw.text.trim(country)

	country = mw.text.unstripNoWiki(country)

	return country
end

return p
