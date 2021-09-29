---
-- @Liquipedia
-- wiki=commons
-- page=Module:Flags
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FlagData = mw.loadData('Module:Flags/MasterData')

local Flags = {}

-- Template functions
function Flags.Flag(frame)
	return Flags._Flag(frame.args[1])
end
function Flags.FlagNoLink(frame)
	return Flags._FlagNoLink(frame.args[1])
end
function Flags.CountryName(frame)
	return Flags._CountryName(frame.args[1])
end

-- Returns a flag with a link to the category page
function Flags._Flag(name)
	if (not name) or name == '' then
		return ''
	end

	local flagData = Flags._getFlagData(name)

	if flagData then
		if flagData.flag ~= 'File:Space filler flag.png' then
			return '<span class="flag">[[' .. flagData.flag ..
				'|' .. flagData.name .. '|link=Category:' .. flagData.name .. ']]</span>'
		else
			return '<span class="flag">[[' .. flagData.flag .. '|link=]]</span>'
		end
	else
		mw.log('Unknown flag: ', name)
		return Flags._safeExpand(mw.getCurrentFrame(), 'Flag/' .. name) .. '[[Category:Pages with unknown flags]]'
	end
end

-- Returns a flag with no link
function Flags._FlagNoLink(name)
	if (not name) or name == '' then
		return ''
	end

	local flagData = Flags._getFlagData(name)

	if flagData then
		return '<span class="flag">[[' .. flagData.flag .. '|' .. flagData.name .. '|link=]]</span>'
	else
		mw.log('Unknown flag: ', name)
		return Flags._safeExpand(mw.getCurrentFrame(), 'FlagNoLink/' .. name) .. '[[Category:Pages with unknown flags]]'
	end
end

-- Returns a flag with no link
function Flags._CountryName(name)
	if (not name) or name == '' then
		return ''
	end

	local flagData = Flags._getFlagData(name)

	if flagData then
		return flagData.name
	else
		mw.log('Unknown flag: ', name)
		return mw.text.trim(mw.text.split(Flags._safeExpand(mw.getCurrentFrame(), 'Flag/' .. name), '|', true)[2] or '')
	end
end

-- Checks the Flags/MasterData tables
function Flags._getFlagData(name)
	local inputName = name or ''
	local flagData

	-- Convert input to lowercase and remove spaces
	inputName = string.lower(string.gsub(inputName, ' ', ''))

	if #inputName == 2 then
		-- Check for a 2-letter code
		local index = FlagData.twoLetter[inputName]
		if index then
			flagData = FlagData.data[index]
		end
	elseif #inputName == 3 then
		-- Check for a 3-letter code
		local index = FlagData.threeLetter[inputName]
		if index then
			flagData = FlagData.data[index]
		end
	else
		-- Check for an alias
		local index = FlagData.aliases[inputName]
		if index then
			flagData = FlagData.data[index]
		end
	end

	-- Lookup the full name anyways if there is no match
	if not flagData then
		flagData = FlagData.data[inputName]
	end

	return flagData
end

-- Fallback to templates when no flag is found
function Flags._safeExpand(frame, templateTitle, templateArgs)
	local result, value = pcall(frame.expandTemplate, frame, {title = templateTitle, args = templateArgs})
	if result then
		return value
	else
		return '[[Template:' .. templateTitle .. ']]'
	end
end

return Flags
