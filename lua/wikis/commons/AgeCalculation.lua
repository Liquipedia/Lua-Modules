---
-- @Liquipedia
-- wiki=commons
-- page=Module:AgeCalculation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local String = require('Module:StringUtils')

local AgeCalculation = {}

local DEFAULT_DATE = os.date('*t', DateExt.defaultTimestamp)
local DEFAULT_DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local MAXIMUM_DAYS_IN_FEBRUARY = 29
local MONTH_DECEMBER = 12
local CURRENT_YEAR = tonumber(mw.getContentLanguage():formatDate('Y')) --[[@as integer]]

local NON_BREAKING_SPACE = '&nbsp;'

---
-- Represents a date
--
-- Before accessing the `year`, `month` and `day` values, please verify
-- whether `isExact` or `isEmpty` are set to false or true respectively.
--
-- `isExact`: Whether this is a complete date, consisting of YYYY-MM-DD
-- `isEmpty`: Whether there is a date here at all.
-- `time`: Time in seconds
---@class AgeDate
---@operator call(...): AgeDate
---@field year integer?
---@field month integer?
---@field day integer?
---@field isExact boolean
---@field isEmpty boolean
---@field location string?
---@field time integer?
local Date = Class.new(
	---@param self self
	---@param dateString string?
	---@param location string?
	function(self, dateString, location)
		if String.isEmpty(dateString) then
			self.isExact = false
			self.isEmpty = true
			return
		end
		---@cast dateString -nil

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

---@return string?
function Date:makeDisplay()
	if self.isEmpty then
		return nil
	end

	local formatString = self:_getFormatString()
	local timestamp = self:getEarliestPossible()

	if formatString then
		local formatted = os.date(formatString, timestamp) --[[@as string]]
		if not String.isEmpty(self.location) then
			formatted = formatted .. '<br>' .. self.location
		end

		return formatted
	end

	return nil
end

---@return string?
function Date:makeIso()
	if self.isEmpty or not self.isExact then
		return
	end

	return self.year .. '-' .. self.month .. '-' .. self.day
end

---@return string?
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

---@return integer
function Date:getEarliestPossible()
	return os.time({
		year = self.year or DEFAULT_DATE.year,
		month = self.month or DEFAULT_DATE.month,
		day = self.day or DEFAULT_DATE.day,
	})
end

---@return integer
function Date:getLatestPossible()
	return os.time({
		year = self.year or CURRENT_YEAR,
		month = self.month or MONTH_DECEMBER,
		day = self.day or DEFAULT_DAYS_IN_MONTH[self.month or MONTH_DECEMBER],
	})
end

---@class BirthDate: AgeDate
local BirthDate = Class.new(Date)
---@class DeathDate: AgeDate
local DeathDate = Class.new(Date)

---@class Age
---@operator call(...): Age
---@field birthDate BirthDate
---@field deathDate DeathDate
local Age = Class.new(
	function(self, birthDate, deathDate)
		self.birthDate = birthDate
		self.deathDate = deathDate
	end
)

---@return string|number?
function Age:calculate()
	local endDate
	if self.deathDate.isEmpty then
		endDate = os.time()
	else
		endDate = self.deathDate.time
	end

	if self.birthDate.isExact and (self.deathDate.isExact or self.deathDate.isEmpty) then
		---@cast endDate -nil
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

---@return {death: string?, birth: string?}
function Age:makeDisplay()
	local age = self:calculate()
	local result = {
		death = nil,
		birth = nil,
	}

	if age ~= nil then
		if not self.deathDate.isEmpty then
			result.death = self.deathDate:makeDisplay() .. ' (aged' .. NON_BREAKING_SPACE .. age .. ')'
			result.birth = self.birthDate:makeDisplay()
		else
			result.birth = self.birthDate:makeDisplay() .. ' (age' .. NON_BREAKING_SPACE .. age .. ')'
		end
	else
		result.death = self.deathDate:makeDisplay()
		result.birth = self.birthDate:makeDisplay()
	end

	return result
end

---@param seconds integer
---@return integer
function Age:_secondsToAge(seconds)
	return math.floor(seconds / 60 / 60 / 24 / 365.2425)
end

---@param args table
---@return Age
function AgeCalculation.raw(args)
	local birthLocation = args.birthlocation
	local birthDate = BirthDate(args.birthdate, birthLocation)
	local deathLocation = args.deathlocation
	local deathDate = DeathDate(args.deathdate, deathLocation)

	AgeCalculation._assertValidDates(birthDate, deathDate)

	return Age(birthDate, deathDate)
end

---@param args table
---@return {birthDateIso: string?, deathDateIso: string?, categories: string[], birth: string?, death: string?}
function AgeCalculation.run(args)
	local ageRaw = AgeCalculation.raw(args)
	local age = ageRaw:makeDisplay()

	local birthDate = ageRaw.birthDate
	local deathDate = ageRaw.deathDate

	local categories = Array.append({},
		age.birth and not birthDate.isExact and 'Incomplete birth dates' or nil,
		birthDate.year and (birthDate.year .. ' births') or nil,
		age.death and not deathDate.isExact and 'Incomplete death dates' or nil
	)

	return {
		birthDateIso = birthDate:makeIso(),
		deathDateIso = deathDate:makeIso(),
		birth = age.birth,
		death = age.death,
		categories = categories,
	}
end

---@param birthDate BirthDate
---@param deathDate DeathDate
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

---@param date AgeDate
---@param dateType string
function AgeCalculation._showErrorForDateIfNeeded(date, dateType)
	if date.month then
		if date.month > 12 or date.month == 0 then
			error(dateType .. ' month out of allowed range. Please use ISO 8601 date format YYYY-MM-DD')
		end
		if
			date.day and (
				date.day == 0 or
				(date.month == 2 and date.day > MAXIMUM_DAYS_IN_FEBRUARY) or
				(date.month ~= 2 and date.day > DEFAULT_DAYS_IN_MONTH[date.month])
			)
		then
			error(dateType .. ' day out of allowed range. Please use ISO 8601 date format YYYY-MM-DD')
		end
	end
end

return Class.export(AgeCalculation)
