local Class = require('Module:Class')
local String = require('Module:String')
local Variables = require('Module:Variables')

local AgeCalculation = {}

local _EPOCH_DATE = { year = 1970, month = 1, day = 1 }
local _DEFAULT_DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
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
	function(self, dateString)
		if String.isEmpty(dateString) then
			self.isExact = false
			self.isEmpty = true
			return
		end

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
		return ''
	end

	local timestamp = self:getEarliestPossible()

	return os.date('%B %e, %Y', timestamp)
end

function Date:makeIso()
	if self.isEmpty then
		return ''
	end

	local year = self.year or _EPOCH_DATE.year
	local month = self.month or _EPOCH_DATE.month
	local day = self.day or _EPOCH_DATE.day

	return year .. '-' .. month .. '-' .. day
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
		end

		result.birth = self.birthDate:makeDisplay() .. ' (age ' .. age .. ')'
	end

	return result
end

function Age:_secondsToAge(seconds)
	return math.floor(seconds / 60 / 60 / 24 / 365.25)
end

function AgeCalculation.run(args)
	local birthDate = BirthDate(args.birthdate)
	local deathDate = DeathDate(args.deathdate)

	AgeCalculation._assertValidDates(birthDate, deathDate)

	local age = Age(birthDate, deathDate):makeDisplay()

	Variables.varDefine('player_birthdate', birthDate:makeIso())
	Variables.varDefine('player_deathdate', deathDate:makeIso())

	return {
		birth = age.birth,
		death = age.death
	}
end

function AgeCalculation._assertValidDates(birthDate, deathDate)
	local earliestPossibleBirthDate = birthDate:getEarliestPossible()
	if deathDate.isExact then
		if earliestPossibleBirthDate > deathDate:getLatestPossible() then
			return error('Death date can not be before birth date')
		end

		if deathDate:getEarliestPossible() > os.time() then
			return error('Death date out of allowed range')
		end
	end

	if earliestPossibleBirthDate > os.time() or
		earliestPossibleBirthDate < os.time(_EPOCH_DATE) then
			return error('Birth date out of allowed range')
	end
end

return Class.export(AgeCalculation)
