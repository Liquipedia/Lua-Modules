---
-- @Liquipedia
-- wiki=commons
-- page=Module:Player/Util/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Flags = require('Module:Flags')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local StarcraftTournamentUtil = require('Module:Tournament/Util/Starcraft')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Logic = require('Module:Logic')

local globalVars = PageVariableNamespace({cached = true})
local playerVars = PageVariableNamespace({namespace = 'Player', cached = true})

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
		return String.nilIfEmpty(pageName), displayName
	end
	return nil, String.nilIfEmpty(name)
end

--[[
Asks LPDB for the race and flag of a player using the player record.

For specific uses only.
]]
StarcraftPlayerUtil.fetchPlayer = FnUtil.memoize(function(resolvedPageName)
	local rows = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. resolvedPageName:gsub(' ', '_') .. ']]',
		query = 'nationality, extradata',
	})

	local record = rows[1]
	if record then
		local raceHistory = Logic.readBool(record.extradata.racehistorical)
			and StarcraftPlayerUtil.fetchRaceHistory(resolvedPageName)
			or nil

		return {
			flag = String.nilIfEmpty(Flags.CountryName(record.nationality)),
			race = StarcraftPlayerUtil.readRace(record.extradata.race),
			raceHistory = raceHistory,
		}
	end
end)

--[[
For specific uses only.
]]
function StarcraftPlayerUtil.fetchPlayerRace(resolvedPageName, date)
	local lpdbPlayer = StarcraftPlayerUtil.fetchPlayer(resolvedPageName)
	if lpdbPlayer and lpdbPlayer.raceHistory then
		date = date or StarcraftTournamentUtil.getContextualDateOrNow()
		local entry = Array.find(lpdbPlayer.raceHistory, function(entry) return entry.startDate <= date end)
		return StarcraftPlayerUtil.readRace(entry.race)
	else
		return lpdbPlayer and lpdbPlayer.race
	end
end

--[[
For specific uses only.
]]
function StarcraftPlayerUtil.fetchPlayerFlag(resolvedPageName)
	local lpdbPlayer = StarcraftPlayerUtil.fetchPlayer(resolvedPageName)
	return lpdbPlayer and String.nilIfEmpty(Flags.CountryName(lpdbPlayer.flag))
end

--[[
Asks LPDB for the historical races of a player using the playerrace data point.

For specific uses only.
]]
function StarcraftPlayerUtil.fetchRaceHistory(resolvedPageName)
	local conditions = {
		'[[type::playerrace]]',
		'[[pagename::' .. resolvedPageName:gsub(' ', '_') .. ']]',
	}
	local rows = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = table.concat(conditions, ' and '),
		query = 'information, extradata',
	})

	return Array.map(rows, function(row)
		return {
			endDate = row.extradata.enddate,
			race = StarcraftPlayerUtil.readRace(row.information),
			startDate = row.extradata.startdate,
		}
	end)
end

--[[
Asks LPDB for the flag and race of a non-notable player using the
LowTierPlayerInfo data points.

For specific uses only.
]]
StarcraftPlayerUtil.fetchNonNotable = FnUtil.memoize(function(resolvedPageName)
	local conditions = {
		'[[type::LowTierPlayerInfo]]',
		'[[namespace::136]]', -- Data: namespace
		'[[name::' .. resolvedPageName .. ']]',
	}
	local records = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = table.concat(conditions, ' and '),
		query = 'extradata',
	})
	local record = records[1]
	return record
		and {
			flag = String.nilIfEmpty(Flags.CountryName(record.extradata.flag)),
			race = record.extradata.race,
		}
		or nil
end)

--[[
Asks LPDB for the flag and race of a player using an arbitary sample of
match2player records.

For specific uses only.
]]
StarcraftPlayerUtil.fetchMatch2Player = FnUtil.memoize(function(resolvedPageName)
	local conditions = {
		'[[name::' .. resolvedPageName .. ']]',
	}
	local records = mw.ext.LiquipediaDB.lpdb('match2player', {
		conditions = table.concat(conditions, ' and '),
		limit = 30,
		query = 'flag, extradata',
	})
	local flags = Array.map(records, function(record) return record.flag end)
	local races = Array.map(records, function(record) return StarcraftPlayerUtil.readRace(record.extradata.faction) end)

	local function majority(xs)
		local groups = Array.groupBy(xs, FnUtil.identity)
		local largest = Array.maxBy(groups, function(group) return #group end)
		if largest and 0.5 < #largest / #records then
			return largest[1]
		else
			return nil
		end
	end

	return {
		flag = String.nilIfEmpty(Flags.CountryName(majority(flags))),
		race = majority(races),
	}
end)

--[[
Asks LPDB for the team a player belonged to on a particular date, using the
teamhistory data point.

For specific uses only.
]]
function StarcraftPlayerUtil.fetchTeamHistoryEntry(resolvedPageName, date)
	date = date or StarcraftTournamentUtil.getContextualDateOrNow()

	local conditions = {
		'[[type::teamhistory]]',
		'[[pagename::' .. resolvedPageName:gsub(' ', '_') .. ']]',
		'([[extradata_joindate::<' .. date .. ']] or [[extradata_joindate::' .. date .. ']])',
		'[[extradata_joindate::>]]',
		'[[extradata_leavedate::>' .. date .. ']]',
		'[[extradata_position::player]]',
	}
	local records = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = table.concat(conditions, ' and '),
		query = 'information, extradata',
	})
	return records[1] and StarcraftPlayerUtil.teamHistoryEntryFromRecord(records[1])
end

function StarcraftPlayerUtil.teamHistoryEntryFromRecord(entryRecord)
	return {
		joinDate = entryRecord.extradata.joindate,
		leaveDate = entryRecord.extradata.leavedate,
		template = entryRecord.information:lower(),
	}
end

--[[
For specific uses only.
]]
function StarcraftPlayerUtil.fetchTeamTemplate(resolvedPageName, date)
	local entry = StarcraftPlayerUtil.fetchTeamHistoryEntry(resolvedPageName, date)
	if entry then
		local raw = mw.ext.TeamTemplate.raw(entry.template, date)
		return raw and raw.templatename
	end
end

--[[
Fills in the flag, race, and pageName of a player if they are missing. Uses
data previously stored in page variables, and failing that, queries LPDB. The
results are saved to page variables for future use. This function mutates the
player argument.

The flag and race of a player are determined first from the arguments, then
page variables, and finally LPDB. The returned race is a single character
string, either 'p' 't' 'z' or 'r', or nil if unspecified.

player.displayName
player.pageName
player.race: Either 'p' 't' 'z' 'r' or 'u'. Will look up if nil.
player.flag: A country name like 'Netherlands'. Will look up if nil.
player.pageIsResolved: Indicates that the pageName is resolved (not a redirect)
so it does not need to be resolved again.

options.date: Needed if the player used a different race in the past. Defaults
to the tournament end date or now.
options.fetchPlayer: Whether to use the LPDB player record. Enabled by default.
options.fetchNonNotable: Whether to use LPDB records from Data:PlayerData. Disabled by default.
options.fetchMatch2Player: Whether to use the player's recent matches. Disabled by default.
options.savePageVar: Whether to save results to page variables. Enabled by default.
]]
function StarcraftPlayerUtil.syncPlayer(player, options)
	options = options or {}

	local function nonNotable()
		return options.fetchNonNotable
			and StarcraftPlayerUtil.fetchNonNotable(player.pageName)
			or nil
	end

	local function match2Player()
		return options.fetchMatch2Player
			and StarcraftPlayerUtil.fetchMatch2Player(player.pageName)
			or nil
	end

	StarcraftPlayerUtil.populatePageName(player)

	player.flag = player.flag
		or String.nilIfEmpty(Flags.CountryName(globalVars:get(player.displayName .. '_flag')))
		or options.fetchPlayer ~= false and StarcraftPlayerUtil.fetchPlayerFlag(player.pageName)
		or nonNotable() and nonNotable().flag
		or match2Player() and match2Player().flag

	player.race = player.race
		or globalVars:get(player.displayName .. '_race')
		or options.fetchPlayer ~= false and StarcraftPlayerUtil.fetchPlayerRace(player.pageName, options.date)
		or nonNotable() and nonNotable().race
		or match2Player() and match2Player().race
		or 'u'

	if options.savePageVar ~= false then
		StarcraftPlayerUtil.saveToPageVars(player)
	end

	return player
end

--[[
Same as StarcraftPlayerUtil.syncPlayer, except it does not save the player's
flag and race to page variables.
]]
function StarcraftPlayerUtil.populatePlayer(player, options)
	return StarcraftPlayerUtil.syncPlayer(player, Table.merge(options, {savePageVar = false}))
end

--[[
For specific uses only.
]]
function StarcraftPlayerUtil.populatePageName(player)
	player.pageName = player.pageIsResolved and player.pageName
		or player.pageName and mw.ext.TeamLiquidIntegration.resolve_redirect(player.pageName)
		or globalVars:get(player.displayName .. '_page')
		or player.displayName and mw.ext.TeamLiquidIntegration.resolve_redirect(player.displayName)

	player.pageIsResolved = player.pageName and true or nil
end

--[[
Saves the pageName, flag, and race of a player to page variables, so that
editors do not have to duplicate the same info later on.
]]
function StarcraftPlayerUtil.saveToPageVars(player)
	if player.pageName then
		globalVars:set(player.displayName .. '_page', player.pageName)
	end
	if player.flag then
		globalVars:set(player.displayName .. '_flag', player.flag)
	end
	if player.race then
		globalVars:set(player.displayName .. '_race', player.race)
	end
end

--[[
Fills in the team of the player on the specified date, if it is not specified
in the arguments. The team is determined from previous invocations of
StarcraftPlayerUtil.syncTeam, and then lpdb. The team is stored to page
variables for future use. The returned value is a team template, or nil if the
player is teamless or if the team cannot be determined.

pageName: page of the player, and must be resolved (cannot be a redirect).
template: team template, or nil. Specify 'noteam' to clear a previously set team

options.date: Needed if the player was on a different team in the past.
Defaults to the tournament end date or now.
options.fetchPlayer: Whether to look up lpdb records of the player page. Enabled
by default.
options.savePageVar: Whether to save results to page variables. Enabled by
default.
options.useTimeless: Whether to use the template passed to a previous call of
StarcraftPlayerUtil.syncTeam. Enabled by default.
]]
function StarcraftPlayerUtil.syncTeam(pageName, template, options)
	options = options or {}
	local date = options.date or StarcraftTournamentUtil.getContextualDateOrNow()

	local historyVar = playerVars:get(pageName .. '.teamHistory')
	local history = historyVar and Json.parse(historyVar) or {}
	local pageVarEntry = options.useTimeless ~= false and history.timeless
		or Array.find(history, function(entry) return date < entry.leaveDate end)

	local timelessEntry = template and {
		isResolved = pageVarEntry and template == pageVarEntry.template,
		isTimeless = true,
		template = template,
	}

	local entry = timelessEntry
		or pageVarEntry
		or options.fetchPlayer ~= false and StarcraftPlayerUtil.fetchTeamHistoryEntry(pageName, options.date)

	if entry and not entry.isResolved then
		local raw = mw.ext.TeamTemplate.raw(entry.template, options.date)
		entry.template = raw and raw.templatename
		entry.isResolved = true
	end

	if options.savePageVar ~= false
		and (entry and entry.template) ~= (pageVarEntry and pageVarEntry.template) then
		if entry.isTimeless then
			history.timeless = entry
		else
			table.insert(history, entry)
			Array.sortInPlaceBy(history, function(e) return e.joinDate end)
		end
		playerVars:set(pageName .. '.teamHistory', Json.stringify(history))
	end

	return entry and entry.template
end

--[[
Same as StarcraftPlayerUtil.syncTeam, except it does not save the player's
team to page variables.
]]
function StarcraftPlayerUtil.populateTeam(pageName, template, options)
	return StarcraftPlayerUtil.syncTeam(pageName, template, Table.merge(options, {savePageVar = false}))
end

return StarcraftPlayerUtil
