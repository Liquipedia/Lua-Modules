---
-- @Liquipedia
-- wiki=commons
-- page=Module:Locale
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---
-- @author Vogan
-- @author Rapture
--

local Class = require('Module:Class')

local Locale = {}

function Locale.getISOCountry(country)

	if country == nil or country == '' then
		return ''
	end

	local data = mw.loadData('Module:Locale/data/countries')

	local isoCountry = data[country:lower()]

	if isoCountry ~= nil then
		return isoCountry
	end

	mw.log('No country found in Module:Locale/data/countries: ' .. country)
	return ''

end

function Locale.formatLocation(args)
	local formattedLocation = ''

	if args.city ~= nil and args.city ~= '' then
		formattedLocation = args.city .. ',&nbsp;'
	end

	formattedLocation = formattedLocation .. (args.country or '')
	return formattedLocation
end


return Class.export(Locale, {frameOnly = true})
