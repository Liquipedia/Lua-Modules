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
local _EPOCH_FIELD = { year = 1970, month = 1, day = 1 }
local _CURRENT_FIELD = os.date('*t', os.time())
local _CURRENT_ISO = _LANG:formatDate('c')
local _CURRENT_YEAR = tonumber(_LANG:formatDate('Y'))
local _DEFAULT_DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

function AgeCalculation.run(birth, birthLocation, death, shouldStore)
	local birthFields = AgeCalculation._parseDate(birth) -- This is now an array of a date
	local deathFields = AgeCalculation._parseDate(death)

	--error for some cases that are not allowed
	AgeCalculation._assertValidDates(birthFields, deathFields)

	local age = AgeCalculation._processAge(birthFields, deathFields)

	--determine the display returned from this function
	local birthDisplay
	if birthFields.display then
		birthDisplay = birthFields.display .. age.birthDisplay
		if birthLocation then
			birthDisplay = birthDisplay .. '<br>' .. birthLocation
		end
		if shouldStore and not birthFields.exact then
			birthDisplay = birthDisplay .. '[[Category:Incomplete birth dates]]'
		end
		if shouldStore and birthFields.year then
			birthDisplay = birthDisplay .. '[[Category:' .. birthFields.year .. 'births]]'
		end
	end
	local deathDisplay
	if deathFields.display then
		deathDisplay = deathFields.display .. age.deathDisplay
		if shouldStore and not deathFields.exact then
			deathDisplay = deathDisplay .. '[[Category:Incomplete death dates]]'
		end
	end

	return birthDisplay, deathDisplay, birthFields.store, deathFields.store
end

function AgeCalculation._parseDate(date)
	local dateField = mw.text.split(date or '', '-')
	dateField.year = tonumber(dateField[1])
	dateField.month = tonumber(dateField[2])
	dateField.day = tonumber(dateField[3])
	return AgeCalculation._processDateFields(dateField)
end

function AgeCalculation._processAge(birthFields, deathFields)
	--set an empty age display field (we need different
	--displays depending if the person is alive or not)
	local age = { birthDisplay = '', deathDisplay = '' }
	if not birthFields.display then
		return age
	end

	local calculatedAgeDisplay = AgeCalculation._getAgeDisplay(birthFields, deathFields)

	--add the age display to the field according if the person is alive
	if deathFields.display and calculatedAgeDisplay then
		age.deathDisplay = ' (aged ' .. calculatedAgeDisplay .. ')'
	elseif calculatedAgeDisplay then
		age.birthDisplay = ' (age ' .. calculatedAgeDisplay .. ')'
	end

	return age
end

function AgeCalculation._getAgeDisplay(birthFields, deathFields)
	--if the person is alive set the deathFileds to current date
	--as we need to calculate against it
	if not deathFields.display then
		deathFields.year = _CURRENT_FIELD.year
		deathFields.month = _CURRENT_FIELD.month
		deathFields.day = _CURRENT_FIELD.day
		deathFields.exact = true
	end

	--if both birth and "death" date are exact we do have a singular age
	--hence we determine that and use it for the display
	if birthFields.exact and deathFields.exact then
		return AgeCalculation._calculateAge(birthFields, deathFields)
	--if one or both are not exact but we know the years determine a min age and a max age
	--and determine the age display from them
	elseif deathFields.year and birthFields.year then
		--minimum age is calculated from the maximum birth date (or the real one if given)
		--and the minimum death/current date (or the exact one if known)
		local minAge = AgeCalculation._calculateAge(
			birthFields.maxPossible or birthFields,
			deathFields.minPossible or deathFields
		)
		--maximum age is calculated from the minimum birth date (or the real one if given)
		--and the maximum death/current date (or the exact one if known)
		local maxAge = AgeCalculation._calculateAge(
			birthFields.minPossible or birthFields,
			deathFields.maxPossible or deathFields
		)
		--if both min and max are the same the value is singular
		--else we have a 1 year range to display
		if minAge == maxAge then
			return minAge
		else
			return minAge .. '-' .. maxAge
		end
	end

	return nil
end

function AgeCalculation._calculateAge(startDate, endDate)
	--age = death/current year - birth year
	local age = endDate.year - startDate.year
	--unless ...
	if
		--death/current month < birth month
		endDate.month < startDate.month or (
			--or the months are the same but the day of death/current < day of birth
			endDate.month == startDate.month and endDate.day < startDate.day
		)
	then
		age = age - 1
	end
	return age
end

--[[
The _processDateFields function processes a dateField and
returns values depending on the exactness of the dateField

if the dateField is exact the following is returned: {
	year, month, day,
	exact = true,
	iso = date as iso string
	display = Date Display String,
	store = Date String for storage (format Y-M-D)
}
else it returns (in case we have a valid date, i.e. one that has year or both day and month): {
	year, month, day, <-- some of those are empty
	display = Date Display String,
	minPossible = { year, month, day } <-- minimum date possible with the known partials
	isoMinPossible = minPossible as iso string
	maxPossible = { year, month, day } <-- maximum date possible with the known partials (*)
	isoMaxPossible = maxPossible as iso string
}

(*) ignoring leap years (Feb. 29th) as they are irrelevant for the further calculations
]]--
function AgeCalculation._processDateFields(date)
	--if year is not set and month or day is not set return an empty table
	if not date.year and not (date.month and date.day) then
		return {}
	--if year, month and day are set we have an exact date
	elseif date.year and date.month and date.day then
		return AgeCalculation._processExactDateFields(date)
	--else we do not have an exact date
	else
		return AgeCalculation._processPartialDateFields(date)
	end
end

function AgeCalculation._processExactDateFields(date)
	date.store = AgeCalculation._makeDateString(date)
	date.iso = _LANG:formatDate('c', date.store)
	date.exact = true
	date.display = _LANG:formatDate('F j, Y', date.store)
	return date
end

function AgeCalculation._processPartialDateFields(date)
	--determine the displayFormatString according to the known parts of the date
	local displayFormatString = AgeCalculation._getDisplayFormatSrtring(date)

	--set a minimum date for the given date partials
	--(by filling unknown partials up with EPOCH time partials)
	date.minPossible = {
		year = date.year or _EPOCH_FIELD.year,
		month = date.month or _EPOCH_FIELD.month,
		day = date.day or _EPOCH_FIELD.day
	}
	date.isoMinPossible = _LANG:formatDate('c', AgeCalculation._makeDateString(date.minPossible))

	--set a maximum date for the given date partials (by filling
	--unknown partials up with current year/december/the last day of the month,
	--but ignoring leap years)
	date.maxPossible = {
		year = date.year or _CURRENT_YEAR,
		month = date.month or 12
	}
	--ignoring leap years here as they are irrlevant for the further calculations
	date.maxPossible.day = date.day or _DEFAULT_DAYS_IN_MONTH[date.maxPossible.month]
	local dateString = AgeCalculation._makeDateString(date.maxPossible)
	date.isoMaxPossible = _LANG:formatDate('c', dateString)

	--set the display according to the above determined format string
	date.display = _LANG:formatDate(displayFormatString, dateString)

	return date
end

function AgeCalculation._getDisplayFormatSrtring(date)
	-- if year and month are known
	if date.year and date.month then
		return 'F, Y'
	-- if day and month are known
	elseif date.month and date.day then
		return 'F j'
	-- if year is known, but not month (display only year)
	else
		return 'Y'
	end
end

function AgeCalculation._makeDateString(date)
	return date.year .. '-' .. date.month .. '-' .. date.day
end

function AgeCalculation._assertValidDates(firstDate, secondDate)
	local isoFirstMin = firstDate.iso or firstDate.isoMinPossible
	local isoSecondMax = secondDate.iso or secondDate.isoMaxPossible
	local isoSecondMin = secondDate.iso or secondDate.isoMaxPossible
	if isoFirstMin and isoSecondMax and isoFirstMin > isoSecondMax then
		error('Death date can not be before birth date')
	elseif isoFirstMin and  (isoFirstMin > _CURRENT_ISO or isoFirstMin < _EPOCH) then
		error('Birth date out of allowed range')
	elseif isoSecondMin and isoSecondMin > _CURRENT_ISO then
		error('Death date out of allowed range')
	end
end

return Class.export(AgeCalculation)
