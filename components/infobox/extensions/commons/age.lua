---
-- @Liquipedia
-- wiki=commons
-- page=Module:AgeCalculation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:String')
local Variables = require('Module:Variables')

local AgeCalculation = {}

local _EPOCH_DATE = { year = 1970, month = 1, day = 1 }
local _DEFAULT_DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local _MAXIMUM_DAYS_IN_FEBRUARY = 29
local _MONTH_DECEMBER = 12
local _CURRENT_YEAR = tonumber(mw.getContentLanguage():formatDate('Y'))

---
-- Represents a date
--
-- Before accessing the `year`, `month` and `day` values, please verify
-- whether `isExact` or `isEmpty` are set to false or true respectively.
--
-- `isExact`: Whether this is a complete date, consisting of YYYY-MM-DD
-- `isEmpty`: Whether there is a date here at all.
-- `time`: Time in seconds
local Date = Class.new(
	function(self, dateString, location)
		if String.isEmpty(dateString) then
			self.isExact = false
			self.isEmpty = true
			return
		end

		self.location = location
		self.isEmpty = false
		self.isExact = true
		local fields = mw.text.split(dateString, '-')

		self.year = tonumber(fields[1])
		self.month = tonumber(fields[2])
		self.day = tonumber(fields[3])

		if self.year == nil or self.month == nil or self.day == nil then
			self.isExact = false
		else
			self.time = os.time({
				year = self.year,
				month = self.month,
				day = self.day
			})
		end

	end
)

function Date:makeDisplay()
	if self.isEmpty then
		return nil
	end

	local formatString = self:_getFormatString()
	local timestamp = self:getEarliestPossible()

	if formatString then
		local formatted = os.date(formatString, timestamp)
		if not String.isEmpty(self.location) then
			formatted = formatted .. '<br>' .. self.location
		end

		return formatted
	end

	return nil
end

function Date:makeIso()
	if self.isEmpty or not self.isExact then
		return ''
	end

	local year = self.year
	local month = self.month
	local day = self.day

	return year .. '-' .. month .. '-' .. day
end

function Date:_getFormatString()
	if self.year then
		if self.month and self.day then
			return '%B %e, %Y'
		elseif self.month then
			return '%B, %Y'
		else -- Ignore day if we do not know the month
			return '%Y'
		end
	elseif self.month and self.day then
		return '%B %e'
	elseif self.month then
		return '%B'
	end
end

function Date:getEarliestPossible()
	return os.time({
		year = self.year or _EPOCH_DATE.year,
		month = self.month or _EPOCH_DATE.month,
		day = self.day or _EPOCH_DATE.day,
	})
end

function Date:getLatestPossible()
	return os.time({
		year = self.year or _CURRENT_YEAR,
		month = self.month or _MONTH_DECEMBER,
		day = self.day or _DEFAULT_DAYS_IN_MONTH[self.month or _MONTH_DECEMBER],
	})
end

local BirthDate = Class.new(Date)
local DeathDate = Class.new(Date)

local Age = Class.new(
	function(self, birthDate, deathDate)
		self.birthDate = birthDate
		self.deathDate = deathDate
	end
)

function Age:calculate()
	local endDate
	if self.deathDate.isEmpty then
		endDate = os.time()
	else
		endDate = self.deathDate.time
	end

	if self.birthDate.isExact and (self.deathDate.exact or self.deathDate.isEmpty) then
		return self:_secondsToAge(os.difftime(endDate, self.birthDate.time))
	elseif self.birthDate.year and (self.deathDate.year or self.deathDate.isEmpty) then
		local minEndDate
		local maxEndDate
		if self.deathDate.isEmpty then
			minEndDate = os.time()
			maxEndDate = os.time()
		else
			minEndDate = self.deathDate:getEarliestPossible()
			maxEndDate = self.deathDate:getLatestPossible()
		end

		local minAge = self:_secondsToAge(os.difftime(minEndDate, self.birthDate:getLatestPossible()))
		local maxAge = self:_secondsToAge(os.difftime(maxEndDate, self.birthDate:getEarliestPossible()))

		-- If our min and max age values are identical, then we can just display that value. Else,
		-- we have to display a range of ages
		if minAge == maxAge then
			return minAge
		else
			return minAge .. '-' .. maxAge
		end
	end

	return nil
end

function Age:makeDisplay()
	local age = self:calculate()
	local result = {
		death = nil,
		birth = nil,
	}

	if age ~= nil then
		if not self.deathDate.isEmpty then
			result.death = self.deathDate:makeDisplay() .. ' (aged ' .. age .. ')'
			result.birth = self.birthDate:makeDisplay()
		else
			result.birth = self.birthDate:makeDisplay() .. ' (age ' .. age .. ')'
		end
	else
		result.death = self.deathDate:makeDisplay()
		result.birth = self.birthDate:makeDisplay()
	end

	return result
end

function Age:_secondsToAge(seconds)
	return math.floor(seconds / 60 / 60 / 24 / 365.2425)
end

function AgeCalculation.run(args)
	local shouldStore = args.shouldstore
	local birthLocation = args.birthlocation
	local birthDate = BirthDate(args.birthdate, birthLocation)
	local deathDate = DeathDate(args.deathdate)

	AgeCalculation._assertValidDates(birthDate, deathDate)

	local age = Age(birthDate, deathDate):makeDisplay()

	Variables.varDefine('player_birthdate', birthDate:makeIso())
	Variables.varDefine('player_deathdate', deathDate:makeIso())

	if shouldStore then
		if age.birth and not birthDate.isExact then
			age.birth = age.birth .. '[[Category:Incomplete birth dates]]'
		end

		if birthDate.year then
			age.birth = age.birth .. '[[Category:' .. birthDate.year .. ' births]]'
		end

		if age.death and not deathDate.isExact then
			age.death = age.death .. '[[Category:Incomplete death dates]]'
		end
	end

	return {
		birth = age.birth,
		death = age.death
	}
end

function AgeCalculation._assertValidDates(birthDate, deathDate)
	local earliestPossibleBirthDate = birthDate:getEarliestPossible()
	if deathDate.isExact then
		if earliestPossibleBirthDate > deathDate:getLatestPossible() then
			error('Death date can not be before birth date')
		end

		if deathDate:getEarliestPossible() > os.time() then
			error('Death date out of allowed range. Please use ISO 8601 date format YYYY-MM-DD')
		end
	end

	if earliestPossibleBirthDate > os.time() then
			error('Birth date out of allowed range. Please use ISO 8601 date format YYYY-MM-DD')
	end

	AgeCalculation._showErrorForDateIfNeeded(birthDate, 'Birth')
	AgeCalculation._showErrorForDateIfNeeded(deathDate, 'Death')
end

function AgeCalculation._showErrorForDateIfNeeded(date, dateType)
	if date.month then
		if date.month > 12 or date.month == 0 then
			error(dateType .. ' month out of allowed range. Please use ISO 8601 date format YYYY-MM-DD')
		end
		if
			date.day and (
				date.day == 0 or
				(date.month == 2 and date.day > _MAXIMUM_DAYS_IN_FEBRUARY) or
				(date.month ~= 2 and date.day > _DEFAULT_DAYS_IN_MONTH[date.month])
			)
		then
			error(dateType .. ' day out of allowed range. Please use ISO 8601 date format YYYY-MM-DD')
		end
	end
end

return Class.export(AgeCalculation)
