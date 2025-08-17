---
-- @Liquipedia
-- page=Module:Infobox/Extension/TeamHistory/Manual
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local BAD_INPUT_CATEGORY = 'Improperly formatted TeamHistory date'
local ROLE_CLEAN = Lua.requireIfExists('Module:TeamHistoryAuto/cleanRole', {loadData = true})

-- we should bot these eventually...
local ROLE_ALIASES = {
	r = 'Retirement',
	retired = 'Retirement',
}

local TeamHistoryManual = {}

---@param input string|table?
---@return TransferSpan?
function TeamHistoryManual.parse(input)
	local args = input
	if type(input) == 'string' then
		args = Json.parseIfTable(input)
	end
	if not args then return end

	local displayDates = TeamHistoryManual._readDateInput(args[1] or '')
	local team = args.link or args[2]
	local role = args[3]

	role = ROLE_ALIASES[(role or ''):lower()] or role
	if ROLE_CLEAN then
		role = ROLE_CLEAN[(role or ''):lower()] or role
	end

	if role then
		role = String.upperCaseFirst(role)
	end

	return {
		team = team,
		role = role,
		joinDate = TeamHistoryManual._parseDatesToYmd(displayDates.join, args.estimated_start),
		joinDateDisplay = displayDates.join,
		leaveDate = TeamHistoryManual._parseDatesToYmd(displayDates.leave, args.estimated_end),
		leaveDateDisplay = displayDates.leave,
		reference = {},
	}
end

---@param display string
---@param estimate string?
---@return string?
function TeamHistoryManual._parseDatesToYmd(display, estimate)
	if Logic.isNotEmpty(estimate) then
		---@cast estimate -nil
		return DateExt.toYmdInUtc(estimate)
	end

	if display:find('%?') then
		mw.ext.TeamLiquidIntegration.add_category(BAD_INPUT_CATEGORY)
		return
	end

	return DateExt.toYmdInUtc(display)
end

---@param dateInput string
---@return {join: string?, leave: string?}
function TeamHistoryManual._readDateInput(dateInput)
	-- expected input formats (as per existing templates):
		-- YYYY-MM-DD — YYYY-MM-DD
		-- YYYY-MM-DD — '''Present'''

	local joinInput = string.sub(dateInput, 1, 10)
	TeamHistoryManual._checkDate(joinInput)

	local leaveInput = string.sub(dateInput, 11) -- everything after the first date
	local leaveDate
	if not leaveInput:find('Present') then
		leaveDate = leaveInput:gsub('^[^%d]*', '') -- trim away everything before the (second) date
		TeamHistoryManual._checkDate(leaveDate)
	end

	return {
		join = joinInput,
		leave = leaveDate,
	}
end

---@param input string
function TeamHistoryManual._checkDate(input)
	-- can not use DateExt due to the need to allow `?` in the display dates
	if not string.match(input, '[%d%?][%d%?][%d%?][%d%?]%-[%d%?][%d%?]%-[%d%?][%d%?]') then
		mw.ext.TeamLiquidIntegration.add_category(BAD_INPUT_CATEGORY)
	end
end

return TeamHistoryManual
