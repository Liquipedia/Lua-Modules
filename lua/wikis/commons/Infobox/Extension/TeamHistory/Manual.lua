---
-- @Liquipedia
-- page=Module:Infobox/Extension/TeamHistory/Manual
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')
local Json = Lua.import('Module:Json')

local BAD_INPUT_CATEGORY = 'Improperly formatted TeamHistory date'
local ROLE_CLEAN = Lua.requireIfExists('Module:TeamHistoryAuto/cleanRole', {loadData = true})

local TeamHistoryManual = {}

---@param input string|table?
---@return TransferSpan?
function TeamHistoryManual.parse(input)
	local args = input
	if type(input) == 'string' then
		args = Json.parseIfTable(input)
	end
	if not args then return end

	local dates = TeamHistoryManual._readDateInput(args[1])
	local team = args.link or args[2]
	local role = args[3]

	if ROLE_CLEAN then
		role = ROLE_CLEAN[(role or ''):lower()]
	end

	return {
		team = team,
		role = role,
		joinDate = args.estimated_start or dates.join,
		joinDateDisplay = dates.join,
		leaveDate = args.estimated_end or dates.leave,
		leaveDateDisplay = dates.leave,
		reference = {},
	}
end

---@param dateInput any
---@return {join: string?, leave: string?}
function TeamHistoryManual._readDateInput(dateInput)
	-- expected input formats (as per existing templates):
		-- YYYY-MM-DD — YYYY-MM-DD
		-- YYYY-MM-DD — '''Present'''

	local joinInput = string.sub(dateInput, 1, 10)
	local joinDate = DateExt.toYmdInUtc(joinInput)
	if not joinDate then
		mw.ext.TeamLiquidIntegration.add_category(BAD_INPUT_CATEGORY)
	end
	local leaveInput = string.sub(dateInput, 13)
	local leaveDate
	if not leaveInput:find('Present') then
		leaveDate = DateExt.toYmdInUtc(leaveInput)
		if not leaveDate then
			mw.ext.TeamLiquidIntegration.add_category(BAD_INPUT_CATEGORY)
		end
	end

	return {
		join = joinDate,
		leave = leaveDate,
	}
end

return TeamHistoryManual
