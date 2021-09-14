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
local _DEFAULT_DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

function AgeCalculation.run(birth, birthLocation, death, personType, shouldStore)
	local birthFields = AgeCalculation._parseDate(birth) -- This is now an array of a date
	local deathFields = AgeCalculation._parseDate(death)

	--error for some cases that are not allowed
	AgeCalculation._assertValidDates(birthFields, deathFields)

	local age = AgeCalculation._processAge(birthFields, deathFields)

	--determine the display returned from this function
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

function AgeCalculation._parseDate(date)
	local dateField = mw.text.split(date or '', '-')
	for i = 1, 3 do
		dateField[i] = tonumber(dateField[i])
	end
	return AgeCalculation._processDateFields(dateField)
end

function AgeCalculation._processAge(birthFields, deathFields)
	--set an empty age display field
	--(we need different displays depending if the person is alive or not
	local age = { birth = '', death = '' }
	if not birthFields.display then
		return age
	end

	--if the person is alive set the deathFileds to current date
	--as we need to calculate against it
	if not deathFields.display then
		deathFields[1] = _CURRENT_FIELD['year']
		deathFields[2] = _CURRENT_FIELD['month']
		deathFields[3] = _CURRENT_FIELD['day']
		deathFields.exact = true
	end
	local calculatedAgeDisplay
	--if both birth and "death" date are exact we do have a singular age
	--hence we determine that and use it for the display
	if birthFields.exact and deathFields.exact then
		calculatedAgeDisplay = AgeCalculation._calculateAge(birthFields, deathFields)
	--if one or both are not exact but we knwo the years determine a min age and a max age
	--and determine the display from them
	elseif deathFields[1] and birthFields[1] then
		--minimum age is calculated from the maximum birth date (or the real one if given)
		--and the minimum death/current date (or the exact one if known)
		local minAge = AgeCalculation._calculateAge(birthFields.max or birthFields, deathFields.min or deathFields)
		--maximum age is calculated from the minimum birth date (or the real one if given)
		--and the maximum death/current date (or the exact one if known)
		local maxAge = AgeCalculation._calculateAge(birthFields.min or birthFields, deathFields.max or deathFields)
		--if both min and max are the same the value is singular
		--else we have a 1 year range to display
		if minAge == maxAge then
			calculatedAgeDisplay = minAge
		else
			calculatedAgeDisplay = minAge .. '-' .. maxAge
		end
	end

	--add the age display to the field according if the person is alive
	if deathFields.display and calculatedAgeDisplay then
		age.death = ' (aged ' .. calculatedAgeDisplay .. ')'
	elseif calculatedAgeDisplay then
		age.birth = ' (age ' .. calculatedAgeDisplay .. ')'
	end

	return age
end

function AgeCalculation._calculateAge(startDate, endDate)
	--age = death/current year - birth year
	local age = endDate[1] - startDate[1]
	--unless ...
	if
		--death/current month < birth month
		endDate[2] < startDate[2] or (
			--or the months are the same but the day of death/current < day of birth
			endDate[2] == startDate[2] and endDate[3] < startDate[3]
		)
	then
		age = age - 1
	end
	return age
end

--[[
The _processDateFields function processes a dateField and
returns values depending on the exactness of the dateField

if the dateField is exact so the following is returned: {
	1 = year, 2 = month, 3 = day,
	exact = true,
	iso = date as iso string
	display = Date Display String,
	store = Date String for storage (format Y-M-D)
}
else it returns (in case we have a valid date, i.e. one that has year or both day and month): {
	1 = year, 2 = month, 3 = day, <-- some of those are empty
	display = Date Display String,
	min = { 1 = year, 2 = month, 3 = day } <-- minimum date possible with the known partials
	isoMin = min as iso string
	max = { 1 = year, 2 = month, 3 = day } <-- maximum date possible with the known partials (*)
	isoMax = max as iso string
}

(*) ignoring leap years as they are irrelevant for the further calculations
]]--
function AgeCalculation._processDateFields(date)
	--if year is not set and month or day is not set return an empty table
	if not date[1] and not (date[2] and date[3]) then
		return {}
	end

	local dateString
	local displayFormatString
	--if year, month and day are set:
	-- > determine the display String
	-- > set the date as exact
	-- > determine the iso of this date
	-- > determine the storage string (the Y-M-D)
	if date[1] and date[2] and date[3] then
		dateString = table.concat(date, '-')
		date.iso = _LANG:formatDate('c', dateString)
		date.exact = true
		date.display = _LANG:formatDate('F j, Y', dateString)
		date.store = dateString
		return date
	--else set the displayFormatString according to the known parts of the date
	-- > if year and month are known
	elseif date[1] and date[2] then
		displayFormatString = 'F, Y'
	-- > if day and month are known
	elseif date[2] and date[3] then
		displayFormatString = 'F j'
	-- > if year is known, but not month (display only year)
	else
		displayFormatString = 'Y'
	end

	--set a minimum date for the given date partials
	--(by filling unknown partials up with EPOCH time partials)
	local minDate = { date[1] or _EPOCH_FIELD[1], date[2] or _EPOCH_FIELD[2], date[3] or _EPOCH_FIELD[3] }
	date.min = minDate
	date.isoMin = _LANG:formatDate('c', table.concat(minDate, '-'))

	--set a maximum date for the given date partials
	--(by filling unknown partials up with current year
	--and december plus the last day of the month, but
	--ignoring leap years)
	local maxDate = { date[1] or _CURRENT_YEAR, date[2] or 12 }
	maxDate[3] = date[3] or _DEFAULT_DAYS_IN_MONTH[maxDate[2]]
	date.max = maxDate
	dateString = table.concat(maxDate, '-')
	date.isoMax = _LANG:formatDate('c', dateString)

	--set the display according to the above determined format string
	date.display = _LANG:formatDate('c', displayFormatString)

	return date
end

function AgeCalculation._assertValidDates(firstDate, secondDate)
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
