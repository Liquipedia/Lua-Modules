local FnUtil = require('Module:FnUtil')
local Localisation = require('Module:Localisation')
local String = require('Module:String')
local Table = require('Module:Table')

local nilIfEmpty = String.nilIfEmpty

local StarcraftPlayerUtil = {}

local allowedRaces = {
	['p'] = 'p',
	['protoss'] = 'p',
	['t'] = 't',
	['terran'] = 't',
	['z'] = 'z',
	['zerg'] = 'z',
	['r'] = 'r',
	['random'] = 'r',
	['pt'] = 'p',
	['pz'] = 'p',
	['tz'] = 't',
	['tp'] = 't',
	['zt'] = 'z',
	['zp'] = 'z'
	}

-- Reduces a race down to a single character, either 'p', 't', 'z', or 'r', or nil if it can't be done.
function StarcraftPlayerUtil.readRace(race)
	if type(race) == 'string' then
		return allowedRaces[race:lower()] or nil
	end
end

--[===[
Splits a wiki link of a player into a pageName and displayName.

For example:
extractFromLink('[[Dream (Korean Terran player)|Dream]]')
-- returns 'Dream (Korean Terran player)', 'Dream'
--]===]
function StarcraftPlayerUtil.extractFromLink(name)
	name = mw.text.trim(
		name:gsub('%b{}', '')
			:gsub('%b<>', '')
			:gsub('%b[]', '')
	)

	local pageName, displayName = unpack(mw.text.split(name, '|', true))
	if displayName and displayName ~= '' then
		return pageName, displayName
	end
	return nil, name
end

-- Asks LPDB for the race and flag of a player.
function StarcraftPlayerUtil.fetchRaceAndFlag(pageName, date)
	local resolvedPage = mw.ext.TeamLiquidIntegration.resolve_redirect(pageName)

	local rows = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. string.gsub(resolvedPage, ' ', '_') .. ']]',
		query = 'nationality, extradata',
	})

	local row = rows[1]
	if type(row) == 'table' then
		local historicalRace
		if row.extradata.racehistorical == 'true' then
			historicalRace = StarcraftPlayerUtil.fetchHistoricalRace(resolvedPage, date)
		end

		return {
			flag = row.nationality,
			race = historicalRace or StarcraftPlayerUtil.readRace(row.extradata.race),
		}
	end
end

-- Asks LPDB for the main race of a player on a specified date.
function StarcraftPlayerUtil.fetchHistoricalRace(resolvedPage, date)
	local conditions = '[[pagename::' .. string.gsub(resolvedPage, ' ', '_') .. ']] ' ..
		'AND [[type::playerrace]] AND [[extradata_startdate::<' .. date .. ']] ' ..
		'AND [[extradata_enddate::>' .. date .. ']]'
	local rows = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = conditions,
		query = 'information',
	})

	local row = rows[1]
	if type(row) == 'table' then
		return StarcraftPlayerUtil.readRace(row.information)
	end
end

-- Asks LPDB for the team a player belonged to on a particular date. Returns a team template or nil.
function StarcraftPlayerUtil.fetchTeam(pageName, date)
	local resolvedPage = mw.ext.TeamLiquidIntegration.resolve_redirect(pageName)

	local conditions = '[[pagename::' .. string.gsub(resolvedPage, ' ', '_') .. ']] AND [[type::teamhistory]] AND ' ..
		'([[extradata_joindate::<' .. date .. ']] OR [[extradata_joindate::' .. date .. ']]) AND ' ..
		'[[extradata_joindate::>]] AND [[extradata_leavedate::>' .. date .. ']]'
	local rows = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = conditions,
		query = 'information',
	})

	local row = rows[1]
	if type(row) == 'table' then
		return nilIfEmpty(row.information)
	end
end

--[[
Fills in the flag, race, and pageName of a player if they are missing. Uses
data previously stored in page variables, and failing that, queries LPDB. The
results are saved to page variables for future use.

Retrieves the flag and race of a player from first the arguments, then page variables, and finally lpdb.
The returned race is a single character string, either 'p' 't' 'z' or 'r', or nil if unspecified.

player.displayName
player.pageName
player.race: Either 'p' 't' 'z' 'r' or 'u'. Will look up if nil.
player.flag: A flag code like 'nl'. Will look up if nil.
date: Needed if the player used a different race in the past.
]]
function StarcraftPlayerUtil.syncPlayer(player_, date_, dontSave)
	local player = Table.copy(player_)

	if not player.pageName then
		player.pageName = nilIfEmpty(mw.ext.VariablesLua.var(player.displayName .. '_page'))
			or player.displayName
	end

	local lpdbPlayer = FnUtil.memoize(function()
		local date = date_
			or nilIfEmpty(mw.ext.VariablesLua.var('formatted_tournament_edate'))
			or os.date('%F')
		return StarcraftPlayerUtil.fetchRaceAndFlag(player.pageName, date)
	end)

	if not player.flag then
		player.flag = nilIfEmpty(mw.ext.VariablesLua.var(player.displayName .. '_flag'))
			or lpdbPlayer() and lpdbPlayer().flag
	end

	if not player.race then
		player.race = nilIfEmpty(mw.ext.VariablesLua.var(player.displayName .. '_race'))
			or lpdbPlayer() and lpdbPlayer().race
			or 'u'
	end

	if not dontSave then
		StarcraftPlayerUtil.saveToPageVars(player)
	end

	return player
end

--[[
Saves the pageName, flag, and race of a player to page variables, so that
editors do not have to duplicate the same info later on.
]]
function StarcraftPlayerUtil.saveToPageVars(player)
	if player.pageName then
		mw.ext.VariablesLua.vardefine(player.displayName .. '_page', player.pageName)
	end
	if player.flag then
		mw.ext.VariablesLua.vardefine(player.displayName .. '_flag', Localisation.getCountryName{player.flag, 'false'})
	end
	if player.race then
		mw.ext.VariablesLua.vardefine(player.displayName .. '_race', player.race)
	end
end

return StarcraftPlayerUtil
