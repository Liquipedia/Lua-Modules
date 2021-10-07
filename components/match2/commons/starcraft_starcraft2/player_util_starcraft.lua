---
-- @Liquipedia
-- wiki=commons
-- page=Module:Player/Util/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Localisation = require('Module:Localisation')
local StarcraftTournamentUtil = require('Module:Tournament/Util/Starcraft')
local String = require('Module:String')

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
		return nilIfEmpty(pageName), displayName
	end
	return nil, nilIfEmpty(name)
end

-- Asks LPDB for the race and flag of a player.
function StarcraftPlayerUtil.fetchRaceAndFlag(pageName, date)
	local resolvedPage = mw.ext.TeamLiquidIntegration.resolve_redirect(pageName)

	local rows = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. resolvedPage:gsub(' ', '_') .. ']]',
		query = 'nationality, extradata',
	})

	local row = rows[1]
	if type(row) == 'table' then
		local historicalRace
		if row.extradata.racehistorical == 'true' then
			historicalRace = StarcraftPlayerUtil.fetchHistoricalRace(
				resolvedPage,
				date or StarcraftTournamentUtil.getContextualDateOrNow()
			)
		end

		return {
			flag = row.nationality,
			race = historicalRace or StarcraftPlayerUtil.readRace(row.extradata.race),
		}
	end
end

-- Asks LPDB for the main race of a player on a specified date.
function StarcraftPlayerUtil.fetchHistoricalRace(resolvedPage, date)
	local conditions = {
		'[[pagename::' .. resolvedPage:gsub(' ', '_') .. ']]',
		'[[type::playerrace]]',
		'[[extradata_startdate::<' .. date .. ']]',
		'[[extradata_enddate::>' .. date .. ']]',
	}
	local rows = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = table.concat(conditions, ' AND '),
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
	date = date or StarcraftTournamentUtil.getContextualDateOrNow()

	local conditions = {
		'[[pagename::' .. resolvedPage:gsub(' ', '_') .. ']]',
		'[[type::teamhistory]]',
		'([[extradata_joindate::<' .. date .. ']] OR [[extradata_joindate::' .. date .. ']])',
		'[[extradata_joindate::>]]',
		'[[extradata_leavedate::>' .. date .. ']]',
	}
	local rows = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = table.concat(conditions, ' AND '),
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
results are saved to page variables for future use. This function mutates the
player argument.

Retrieves the flag and race of a player from first the arguments, then page
variables, and finally lpdb. The returned race is a single character string,
either 'p' 't' 'z' or 'r', or nil if unspecified.

player.displayName
player.pageName
player.race: Either 'p' 't' 'z' 'r' or 'u'. Will look up if nil.
player.flag: A flag code like 'nl'. Will look up if nil.
date: Needed if the player used a different race in the past. Defaults to the
tournament end date or now.
]]
function StarcraftPlayerUtil.syncPlayer(player, date, dontSave)
	if not player.pageName then
		player.pageName = nilIfEmpty(mw.ext.VariablesLua.var(player.displayName .. '_page'))
			or player.displayName
	end

	local lpdbPlayer = FnUtil.memoize(function()
		return StarcraftPlayerUtil.fetchRaceAndFlag(
			player.pageName,
			date or StarcraftTournamentUtil.getContextualDateOrNow()
		)
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
		mw.ext.VariablesLua.vardefine(player.displayName .. '_flag', Localisation.getCountryName(player.flag, 'false'))
	end
	if player.race then
		mw.ext.VariablesLua.vardefine(player.displayName .. '_race', player.race)
	end
end

return StarcraftPlayerUtil
