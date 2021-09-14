  
---
-- @Liquipedia
-- wiki=commons
-- page=Module:AgeCalculation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local AgeCalculation = {}
local Class = require('Module:Class')

local _LANG = mw.getContentLanguage()

local _EPOCH = _LANG:formatDate('c', '1970-1-1')
local _EPOCH_FIELD = { 1970, 1, 1 }
local _CURRENT_FIELD = os.date('*t', os.time())
local _CURRENT_ISO = _LANG:formatDate('c')
local _CURRENT_YEAR = tonumber(_LANG:formatDate('Y'))
local _DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

function AgeCalculation.run(birth, birthLocation, death, personType, shouldStore)
	--disect the dates into fields
	local birthFields = mw.text.split(birth or '', '-')
	local deathFields = mw.text.split(death or '', '-')
	--strip them to numbers
	for i = 1, 3 do
		birthFields[i] = tonumber(birthFields[i] or '')
		deathFields[i] = tonumber(deathFields[i] or '')
	end

	birthFields = AgeCalculation._processDateFields(birthFields)
	deathFields = AgeCalculation._processDateFields(deathFields)
	AgeCalculation._sanityCeck(birthFields, deathFields)
	local age = AgeCalculation._processAge(birthFields, deathFields)
	
	local birthDisplay
	if birthFields.display then
		birthDisplay = birthFields.display .. age.birth
		if birthLocation then
			birthDisplay = birthDisplay .. '<br>' .. birthLocation
		end
		if shouldStore and not birthFields.exact then
			birthDisplay = birthDisplay .. '[[Category:Incomplete birth dates]]'
		end
		if shouldStore and birthFields[1] then
			birthDisplay = birthDisplay .. '[[Category:' .. birthFields[1] .. 'births]]'
		end
	end
	local deathDisplay 
	if deathFields.display then
		deathDisplay = deathFields.display .. age.death
		if shouldStore and not deathFields.exact then
			deathDisplay = deathDisplay .. '[[Category:Incomplete death dates]]'
		end
	end

	return birthDisplay, deathDisplay, birthFields.store, deathFields.store
end

function AgeCalculation._processAge(birthFields, deathFields)
	local age = { birth = '', death = '' }
	if not birthFields.display then
		return age
	end
	if not deathFields.display then
		key = 'death'
		deathFields[1] = _CURRENT_FIELD['year']
		deathFields[2] = _CURRENT_FIELD['month']
		deathFields[3] = _CURRENT_FIELD['day']
		deathFields.exact = true
	end
	local calculatedAgeDisplay
	if birthFields.exact and deathFields.exact then
		calculatedAgeDisplay = AgeCalculation._calculateAge(birthFields, deathFields)
	elseif deathFields[1] and birthFields[1] then
		local minAge = AgeCalculation._calculateAge(birthFields.max or birthFields, deathFields.min or deathFields)
		local maxAge = AgeCalculation._calculateAge(birthFields.min or birthFields, deathFields.max or deathFields)
		if minAge == maxAge then
			calculatedAgeDisplay = minAge
		else
			calculatedAgeDisplay = minAge .. '-' .. maxAge
		end
	end

	if deathFields.display and calculatedAgeDisplay then
		age.death = ' (aged ' .. calculatedAgeDisplay .. ')'
	elseif calculatedAgeDisplay then
		age.birth = ' (age ' .. calculatedAgeDisplay .. ')'
	end

	return age
end

function AgeCalculation._calculateAge(startDate, endDate)
	local age = endDate[1] - startDate[1]
	if
		endDate[2] < startDate[2] or (
			endDate[2] == startDate[2] and endDate[3] < startDate[3]
		)
	then
		age = age - 1
	end
	return age
end

function AgeCalculation._processDateFields(date)
	if not date[1] and not (date[2] and date[3]) then
		return {}
	end

	local dateString
	local displayFormatString
	if date[1] and date[2] and date[3] then
		dateString = table.concat(date, '-')
		date.iso = _LANG:formatDate('c', dateString)
		date.exact = true
		date.display = _LANG:formatDate('F j, Y', dateString)
		date.store = dateString
		return date
	elseif date[1] and date[2] then
		displayFormatString = 'F, Y'
	elseif date[1] then
		displayFormatString = 'Y'
	else
		displayFormatString = 'F j'
	end

	local minDate = { date[1] or 1970, date[2] or 1, date[3] or 1 }
	date.min = minDate
	date.isoMin = _LANG:formatDate('c', table.concat(minDate, '-'))

	local maxDate = { date[1] or _CURRENT_YEAR, date[2] or 12 }
	maxDate[3] = date[3] or _DAYS_IN_MONTH[maxDate[2]]
	date.max = maxDate
	dateString = table.concat(maxDate, '-')
	date.isoMax = _LANG:formatDate('c', dateString)

	date.display = _LANG:formatDate('c', displayFormatString)

	return date
end

function AgeCalculation._sanityCeck(firstDate, secondDate)
	local isoMin = firstDate.iso or firstDate.isoMin
	local isoMax = secondDate.iso or secondDate.isoMax
	if isoMin and isoMax and isoMin > isoMax then
		error('Death date can not be before birth date')
	elseif isoMin and  (isoMin > _CURRENT_ISO or isoMin < _EPOCH) then
		error('Birth date can not be in the future')
	elseif isoMax and isoMax > _CURRENT_ISO then
		error('Invalid death date (out of allowed date range)')
	end
end

return Class.export(AgeCalculation)
