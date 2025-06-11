---
-- @Liquipedia
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

local PAGE_TO_SECTION = {
	['Singles Pools'] = 'Pools',
	['Round 1 Pools'] = 'R1 Pools',
	['Round 2 Pools'] = 'R2 Pools',
	['Round 3 Pools'] = 'R3 Pools',
}

---@param args table
---@return Html
function CustomHiddenDataBox.run(args)
	args = args or {}
	args.liquipediatier = Tier.toNumber(args.liquipediatier)

	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables

	return BasicHiddenDataBox.run(args)
end

---@param args table
---@param queryResult table
function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	if tonumber(args.phase) then
		Variables.varDefine('num_missing_dates', 7200 * tonumber(args.phase))
	end

	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tournament_date', Variables.varDefault('tournament_enddate'))

	Variables.varDefine('tournament_link', Variables.varDefault('tournament_parent'))
	Variables.varDefine('tournament_mode', Variables.varDefault('tournament_mode', 'singles'))

	Variables.varDefine('tournament_entrants', queryResult.participantsnumber)
	Variables.varDefine('tournament_region', queryResult.extradata.region)

	Variables.varDefine('circuit', queryResult.extradata.circuit)
	Variables.varDefine('circuit_tier', queryResult.extradata.circuit_tier or '')
	Variables.varDefine('circuit2', queryResult.extradata.circuit2)
	Variables.varDefine('circuit2_tier', queryResult.extradata.circuit2_tier or '')

	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_tiertype', Variables.varDefault('tournament_liquipediatiertype'))

	Variables.varDefine('tournament_game', args.game or queryResult.game)

	Variables.varDefine('matchsection',
		args.section or CustomHiddenDataBox._determineMatchSection(mw.title.getCurrentTitle())
	)

	if Variables.varDefault('tournament_mode') == 'squad' then
		Variables.varDefine('disableheads', 'true')
	end

	Variables.varDefine('notranked', String.nilIfEmpty(queryResult.extradata.notranked) or 'false')
end

---@param page Title
---@return string?
function CustomHiddenDataBox._determineMatchSection(page)
	if page.subpageText == 'Singles Bracket' then
		return 'Bracket'
	end

	local titleParts = mw.text.split(page.text , '/', true)

	for key, section in pairs(PAGE_TO_SECTION) do
		if Table.includes(titleParts, key) then
			return section
		end
	end
end

return Class.export(CustomHiddenDataBox, {exports = {'run'}})
