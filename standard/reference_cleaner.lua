---
-- @Liquipedia
-- wiki=commons
-- page=Module:ReferenceCleaner
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local ReferenceCleaner = {}

function ReferenceCleaner.clean(dateWithRef)
	if dateWithRef == nil then
		return ''
	end

	dateWithRef = dateWithRef:gsub('%-%?%?', '-01')
	dateWithRef = dateWithRef:gsub('%-XX', '-01')
	local correctDate = string.match(dateWithRef, '(%d+-%d+-%d+)')
	if correctDate then
		return correctDate
	end

	return ''
end

function ReferenceCleaner.cleanNumber(numberWithRef)
	if numberWithRef == nil then
		return ''
	end

	local correctNumber = string.match(numberWithRef, '(%d+)')
	if correctNumber then
		return correctNumber
	end

	return ''
end

return Class.export(ReferenceCleaner, {frameOnly = true})
