---
-- @Liquipedia
-- page=Module:Ordinal
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Logic = Lua.import('Module:Logic')
local OrdinalData = Lua.import('Module:Ordinal/Data', {loadData = true})
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Ordinal = {}

local DEFAULT_NEGATIVE_SIGN_TEXT = 'negative'

---@class ordinalWrittenOptions
---@field plural boolean?
---@field negativeSignText string?
---@field hyphenate boolean?
---@field capitalize boolean?
---@field concatWithAnd boolean?

---@param valueInput string|number|nil
---@param options ordinalWrittenOptions?
---@return string?
function Ordinal.written(valueInput, options)
	local value = valueInput
	if Logic.isEmpty(value) then
		return
	end
	---@cast value -nil

	-- clean value input
	value = tonumber(string.match(value, '(%d*)%W*$'))
	if not value then
		return
	end

	options = options or {}
	local signText = value >= 0 and ''
		or (options.negativeSignText or DEFAULT_NEGATIVE_SIGN_TEXT) .. ' '
	local concatText = Logic.nilOr(Logic.readBoolOrNil(options.concatWithAnd), true) and ' and ' or ' '

	value = tostring(math.abs(value))
	local decimals = value:match('%.(%d+)')
	if decimals then
		error('Currently only integers are supported in Module:Ordinal.written')
	end

	-- split the value into digit groups of (max) length 3 each
	local digitGroups = {}
	while #value > 3 do
		local digitGroup = string.sub(value, -3, -1)
		table.insert(digitGroups, tonumber(digitGroup))
		value = string.sub(value, 1, -4)
	end
	table.insert(digitGroups, tonumber(value))

	if #digitGroups > Table.size(OrdinalData.groups) then
		error(valueInput .. ' is too large for Module:Ordinal.written')
	end

	local display = ''
	local applyOrdinal = true
	for groupIndex, digitGroup in ipairs(digitGroups) do
		local groupPostfix = ''
		if groupIndex ~= 1 and digitGroup ~= 0 then
			groupPostfix = ' ' .. OrdinalData.groups[groupIndex - 1] .. (applyOrdinal and 'th' or '') .. ' '
			applyOrdinal = false
		end

		local text
		text, applyOrdinal = Ordinal._writtenBelowThousand(digitGroup, applyOrdinal, concatText)
		display = text .. groupPostfix .. display
	end

	display = mw.text.trim(display)

	if String.isEmpty(display) then
		display = OrdinalData.zeroOrdinal
	elseif options.plural then
		display = display .. 's'
	end

	if options.capitalize then
		display = display:gsub('^%l', string.upper)
	end

	if options.hyphenate then
		display = display:gsub('%s', '-')
	end

	return signText .. display
end

---@param value number
---@param applyOrdinal boolean
---@param concatText string
---@return string, boolean
function Ordinal._writtenBelowThousand(value, applyOrdinal, concatText)
	if value == 0 then
		return '', applyOrdinal
	end

	if value < 100 then
		return Ordinal._writtenBelowHundred(value, applyOrdinal), false
	end

	local display = OrdinalData.position[math.floor(value / 100)] .. ' hundred'
	if value % 100 == 0 then
		return display .. (applyOrdinal and 'th' or ''), false
	end

	display = display .. concatText .. Ordinal._writtenBelowHundred(value % 100, applyOrdinal)

	return display, false
end

---@param value number
---@param applyOrdinal boolean
---@return string
function Ordinal._writtenBelowHundred(value, applyOrdinal)
	local lookUp = {
		ones = applyOrdinal and OrdinalData.positionOrdinal or OrdinalData.position,
		tens = applyOrdinal and OrdinalData.positionTensOrdinal or OrdinalData.positionTens,
	}

	if value < 20 then
		return lookUp.ones[value]
	elseif value % 10 == 0 then
		return lookUp.tens[value / 10]
	else
		return lookUp.tens[math.floor(value / 10)] .. '-' .. lookUp.ones[value % 10]
	end
end

---@param value string|number|nil
---@param options {superScript: boolean?}?
---@return string?
function Ordinal.suffix(value, options)
	if Logic.isEmpty(value) then
		return
	end
	---@cast value -nil

	-- clean value input
	value = tonumber(string.match(value, '(%d*)%W*$'))
	if not value then
		return
	end

	options = options or {}
	local residual10 = math.abs(value) % 10
	local residual100 = math.abs(value) % 100

	local suffix
	if residual10 == 1 and residual100 ~= 11 then
		suffix = 'st'
	elseif residual10 == 2 and residual100 ~= 12 then
		suffix = 'nd'
	elseif residual10 == 3 and residual100 ~= 13 then
		suffix = 'rd'
	else
		suffix = 'th'
	end

	if options.superScript then
		return '<sup>' .. suffix .. '</sup>'
	end

	return suffix
end

---Builds the ordinal display of a given value
---@param value string|number|nil
---@param options {superScript: boolean?}?
---@return string?
function Ordinal.toOrdinal(value, options)
	if Logic.isEmpty(value) then
		return
	end

	return value .. (Ordinal.suffix(value, options) or '')
end

---Wiki entry point for `Ordinal.toOrdinal`
---@param frame Frame
---@return string?
function Ordinal.ordinal(frame)
	local args = Arguments.getArgs(frame)

	return Ordinal.toOrdinal(args[1], {superScript = Logic.readBool(args['sup'])})
end

--Legacy entry point
---@deprecated
---@param value string|number|nil
---@param _ nil
---@param superScript boolean?
---@return string?
function Ordinal._ordinal(value, _, superScript)
	return Ordinal.toOrdinal(value, {superScript = superScript})
end

return Ordinal
