---
-- @Liquipedia
-- page=Module:ReferenceCleaner
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local ReferenceCleaner = {}

---@param args {input: string?}
---@return string
function ReferenceCleaner.clean(args)
	local dateWithRef = args.input
	if dateWithRef == nil then
		return ''
	end

	-- due to '-' and '?' being part of the 'magic' characters for patterns
	-- we have to escape them with '%'
	dateWithRef = dateWithRef:gsub('%-%?%?', '-01')
	dateWithRef = dateWithRef:gsub('%-XX', '-01')
	local correctDate = string.match(dateWithRef, '(%d+-%d+-%d+)')
	if correctDate then
		return correctDate
	end

	return ''
end

---@param args {input: string?}
---@return string
---@overload fun(dateWithRef: table): string
function ReferenceCleaner.cleanNumber(args)
	local numberWithRef = args.input
	if numberWithRef == nil then
		return ''
	end

	local correctNumber = string.match(numberWithRef, '(%d+)')
	if correctNumber then
		return correctNumber
	end

	return ''
end

return Class.export(ReferenceCleaner, {frameOnly = true, exports = {'clean', 'cleanNumber'}})
