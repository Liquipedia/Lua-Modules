---
-- @Liquipedia
-- page=Module:Infobox/Extension/TeamHistory/Manual
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
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

---@param args table
---@return TransferSpan
function TeamHistoryManual.parse(args)
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

	local leaveDate = TeamHistoryManual._parseDatesToYmd(displayDates.leave, args.estimated_end)

	return {{
		team = team,
		role = role,
		joinDate = TeamHistoryManual._parseDatesToYmd(displayDates.join, args.estimated_start),
		joinDateDisplay = displayDates.join,
		leaveDate = leaveDate,
		leaveDateDisplay = displayDates.leave,
		reference = {},
		noStorage = displayDates.leave and not leaveDate
	}}
end

---@param display string?
---@param estimate string?
---@param useFallback boolean?
---@return string?
function TeamHistoryManual._parseDatesToYmd(display, estimate, useFallback)
	if not display then
		return
	end
	if Logic.isNotEmpty(estimate) then
		---@cast estimate -nil
		return DateExt.toYmdInUtc(estimate)
	end

	if display:find('%?') then
		mw.ext.TeamLiquidIntegration.add_category(BAD_INPUT_CATEGORY)
		if useFallback then
			display = display
				:gsub('????', '0001')
				:gsub('???', '001')
				:gsub('??', '01')
				:gsub('?', '1')
		end
	end

	return DateExt.toYmdInUtc(display)
end

---@param dateInput string
---@return {join: string?, leave: string?}
function TeamHistoryManual._readDateInput(dateInput)
	-- expected input formats (as per existing templates):
		-- YYYY-MM-DD — YYYY-MM-DD
		-- YYYY-MM-DD — '''Present'''
		-- YYYY — YYYY (used on dota2)

	local dates = Array.parseCommaSeparatedString(dateInput, '—')
	if #dates <= 1 then -- in case someone use a normal `-` with spaces around it as seperator instead
		dates = Array.parseCommaSeparatedString(dateInput, '%s%-%s')
	end

	local joinInput = String.trim(dates[1])
	TeamHistoryManual._checkDate(joinInput)

	local leaveInput = String.trim(dates[2] or 'present')
	local leaveDate
	if not leaveInput:find('[pP]resent') then
		leaveDate = leaveInput
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
