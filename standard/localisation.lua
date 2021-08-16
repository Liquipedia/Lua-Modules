local Localisation = {}
local getArgs = require('Module:Arguments').getArgs
local String = require('Module:StringUtils')

function Localisation.getCountryName(frame)
	local args = getArgs(frame)
	return Localisation._getCountryName(args, frame)
end

function Localisation._getCountryName(args, frame)
	local country = args[1]
	local noentry = args[2] or ''
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
			countryname = (frame or mw.getCurrentFrame())
				:expandTemplate{title = 'Flag/invalidcountry', args = {country}}
		end
	end

	return countryname
end

function Localisation.getLocalisation(frame)
	local args = getArgs(frame)
	return Localisation._getCountryName(args, frame)
end

function Localisation._getLocalisation(args, frame)
	local dataModuleName = 'Module:Localisation/data/localised'
	local country = args[1]
	local noentry = args[2] or ''
	local data = mw.loadData(dataModuleName)

	-- clean the entered country value
	country = Localisation._cleanCountry(country)

	-- First try to look it up
	local localised = data[country]

	-- Return message if none is found
	if localised == nil then
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

return Localisation
