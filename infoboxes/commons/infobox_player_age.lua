local p = {}
local getArgs = require('Module:Arguments').getArgs
local Date = require('Module:Date')._Date

local function stripToNil(text)
	-- If text is a string, return its trimmed content, or nil if empty.
	-- Otherwise return text (which may, for example, be nil).
	if type(text) == 'string' then
		text = text:match('(%S.-)%s*$')
	end
	return text
end

local function message(msg)
	-- Return formatted message text for an error.
	local a = '<strong class="error">Error: '
	local b = '</strong>'
	if mw.title.getCurrentTitle():inNamespaces(0) then
		b = b .. '[[Category:Age error]]'
	end
	return a .. mw.text.nowiki(msg) .. b
end

local function dateParams(output, birthfields, deathfields, DateBirth, DateDeath, DateCurrent)
	local result, resultAge, resultAgeMin, resultAgeMax, y, m, d
	local partial = false

	if birthfields and birthfields[1] then
		y, m, d = tonumber(birthfields[1]), tonumber(birthfields[2]), tonumber(birthfields[3])
		-- only accept partial dates with
		--		year and month
		--		year only
		if DateBirth == nil and y and (m or not d) then
			partial = true
			DateBirth = Date('partial', y, m, d)
		end
		-- do we have a partial or proper birth date
		if DateBirth then
			if partial then
				resultAgeMin = (DateCurrent - DateBirth.partial['last']):age('y')
				resultAgeMax = (DateCurrent - DateBirth.partial['first']):age('y')
				if resultAgeMin == resultAgeMax then
					resultAge = resultAgeMin
				else
					resultAge = resultAgeMin .. '-' .. resultAgeMax
				end
				result = tostring(DateBirth)
			else
				resultAge = (DateCurrent - DateBirth):age('y')
				result = '(<span class="bday">%-Y-%m-%d</span>) </span>%B %-d, %-Y'
				result = '<span style="display:none"> ' .. DateBirth:text(result)
				output["birth_date"] = DateBirth:text('%Y-%m-%d')
			end
			output["birth_monthandday"] = (m and d) and DateBirth:text('%m-%d') or ''
			output["birth_year"] = DateBirth:text('%Y')
			output["birth_display"] = result .. '<span class="noprint"> (age&nbsp;' .. resultAge .. ')</span>'
			output["birth_display_without_age"] = result
		elseif m and d then
			DateBirth = Date(1970, m, d)
			result = '(<span class="bday">%m-%d</span>) </span>%B %-d'
			result = '<span style="display:none"> ' .. DateBirth:text(result)
			output["birth_monthandday"] = DateBirth:text('%m-%d')
			output["birth_display"] = result
			output["birth_display_without_age"] = result
		else
			output["birth_display"] = message('Need valid year, month, day (YYYY-MM-DD)')
			return output
		end
	end

	-- do we have a partial or proper death date
	partial = false
	if deathfields and deathfields[1] then
		output["birth_display"] = output["birth_display_without_age"]
		-- add aged text
		if DateBirth then
			y, m, d = tonumber(deathfields[1]), tonumber(deathfields[2]), tonumber(deathfields[3])
			-- only accept partial dates with
			--		year and month
			--		year only
			if DateDeath == nil and y and (m or not d) then
				partial = true
				DateDeath = Date('partial', y, m, d)
			end
			if DateDeath then
				if partial then
					-- both partial
					if DateBirth.partial and DateBirth.partial['first'] then
						resultAgeMin = (DateDeath.partial['first'] - DateBirth.partial['last']):age('y')
						resultAgeMax = (DateDeath.partial['last'] - DateBirth.partial['first']):age('y')
					-- only death partial
					else
						resultAgeMin = (DateDeath.partial['first'] - DateBirth):age('y')
						resultAgeMax = (DateDeath.partial['last'] - DateBirth):age('y')
					end
				-- only birth partial
				elseif DateBirth.partial and DateBirth.partial['first'] then
					resultAgeMin = (DateDeath - DateBirth.partial['last']):age('y')
					resultAgeMax = (DateDeath - DateBirth.partial['first']):age('y')
				end
				if resultAgeMin and resultAgeMax then
					if resultAgeMin == resultAgeMax then
						resultAge = resultAgeMin
					else
						resultAge = resultAgeMin .. '-' .. resultAgeMax
					end
				-- no partial
				else
					resultAge = (DateBirth - DateDeath):age('y')
				end
			else
				output["death_display"] = message('Need valid year, month, day (YYYY-MM-DD)')
				return output
			end
		end
		if DateDeath then
			if partial then
				result = tostring(DateDeath)
			else
				result = '(<span class="bday">%-Y-%m-%d</span>) </span>%B %-d, %-Y'
				result = '<span style="display:none"> ' .. DateDeath:text(result)
				output["death_date"] = DateDeath:text('%Y-%m-%d')
			end
			output["death_monthandday"] = (m and d) and DateDeath:text('%m-%d') or ''
			output["death_year"] = DateDeath:text('%Y')
			output["death_display"] = result .. (resultAge and
				'<span class="noprint"> (aged&nbsp;' .. resultAge .. ')</span>' or '')
		else
			output["death_display"] = message('Need valid year, month, day (YYYY-MM-DD)')
			return output
		end
	end

	output["birth_display_without_age"] = nil
	return output
end

function p.get(frame)
	local args = getArgs(frame)
	local data = p._get(args)
--mw.logObject(data)

	if (args.setVariables or '') == 'true' then
		for key, item in pairs(data) do
			mw.ext.VariablesLua.vardefine(key, item or '')
		end
	else
		return data
	end
end

function p._get(args)
	local y, m, d
	local output = {
		["birth_display"] = '',
		["birth_monthandday"] = '',
		["birth_year"] = '',
		["birth_date"] = '',
		["death_display"] = '',
		["death_monthandday"] = '',
		["death_year"] = '',
		["death_date"] = ''
	}
	local valid = {
		["birth"] = true,
		["death"] = true
	}

	local birthfields = mw.text.split( (args.birth_date or ''), '-' )
	local deathfields = mw.text.split( (args.death_date or ''), '-' )
	for i = 1, 3 do
		birthfields[i] = stripToNil(birthfields[i])
		deathfields[i] = stripToNil(deathfields[i])
	end
	local DateBirth, DateDeath, DateCurrent, BirthDiff, DeathDiff, DeathBirthDiff
	DateBirth = Date(birthfields[1], birthfields[2], birthfields[3])
	DateDeath = Date(deathfields[1], deathfields[2], deathfields[3])
	DateCurrent = Date('currentdate')
	BirthDiff = DateCurrent - DateBirth
	DeathDiff = DateCurrent - DateDeath
	if DateDeath and DateBirth then
		DeathBirthDiff = DateDeath - DateBirth
	end

	if BirthDiff and BirthDiff.isnegative then
		output["birth_display"] = message('Birth date must not be in the future')
		valid["birth"] = false
	elseif (args.birth_date or '') ~= '' and DateBirth == nil then
		y, m, d = tonumber(birthfields[1]), tonumber(birthfields[2]), tonumber(birthfields[3])
		if y and m and d then
			output["birth_display"] = message('Need valid year, month, day')
			valid["birth"] = false
		end
	end
	if DeathDiff and DeathDiff.isnegative then
		output["death_display"] = message('Death date must not be in the future')
		valid["death"] = false
	elseif (args.death_date or '') ~= '' and DeathBirthDiff == nil then
		y, m, d = tonumber(deathfields[1]), tonumber(deathfields[2]), tonumber(deathfields[3])
		if DateBirth and y and m and d then
			output["death_display"] = message('Need valid year, month, day')
			valid["death"] = false
		end
	elseif BirthDiff and DeathDiff and DeathBirthDiff.isnegative then
		output["death_display"] = message('Death date must be later in time than the birth date')
		valid["birth"], valid["death"] = false, false
	end

	if valid["birth"] and valid["death"] then
		output = dateParams(output, birthfields, deathfields, DateBirth, DateDeath, DateCurrent)
	elseif valid["birth"] then
		output = dateParams(output, birthfields, {}, DateBirth, DateDeath, DateCurrent)
	elseif valid["death"] then
		output = dateParams(output, {}, deathfields, DateBirth, DateDeath, DateCurrent)
	end
	return output
end

return p
