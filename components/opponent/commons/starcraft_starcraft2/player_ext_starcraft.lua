---
-- @Liquipedia
-- wiki=commons
-- page=Module:Player/Ext/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Faction = require('Module:Faction')
local Flags = require('Module:Flags')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local PlayerExt = Lua.import('Module:Player/Ext')

local globalVars = PlayerExt.globalVars

---@class StarcraftPlayerExt: PlayerExt
local StarcraftPlayerExt = Table.copy(PlayerExt)
StarcraftPlayerExt.globalVars = globalVars

---Asks LPDB for the race and flag of a player using the player record.
---
---For specific uses only.
---@param resolvedPageName string
---@return {flag: string?, race: string?, raceHistory: table[]?}?
StarcraftPlayerExt.fetchPlayer = FnUtil.memoize(function(resolvedPageName)
	local rows = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. resolvedPageName:gsub(' ', '_') .. ']]',
		query = 'nationality, extradata',
	})

	local record = rows[1]
	if record then
		local raceHistory = Logic.readBool(record.extradata.racehistorical)
			and StarcraftPlayerExt.fetchRaceHistory(resolvedPageName)
			or nil

		return {
			flag = String.nilIfEmpty(Flags.CountryName(record.nationality)),
			race = Faction.read(record.extradata.race),
			raceHistory = raceHistory,
		}
	end
end)

---For specific uses only.
---@param resolvedPageName string
---@param date string|number|osdate?
---@return string?
function StarcraftPlayerExt.fetchPlayerRace(resolvedPageName, date)
	local lpdbPlayer = StarcraftPlayerExt.fetchPlayer(resolvedPageName)
	if lpdbPlayer and lpdbPlayer.raceHistory then
		date = date or DateExt.getContextualDateOrNow()
		local entry = Array.find(lpdbPlayer.raceHistory, function(entry) return date <= entry.endDate end)
		return entry and Faction.read(entry.race)
	else
		return lpdbPlayer and lpdbPlayer.race
	end
end

---For specific uses only.
---@param resolvedPageName string
---@return string?
function StarcraftPlayerExt.fetchPlayerFlag(resolvedPageName)
	local lpdbPlayer = StarcraftPlayerExt.fetchPlayer(resolvedPageName)
	return lpdbPlayer and String.nilIfEmpty(Flags.CountryName(lpdbPlayer.flag))
end

---Asks LPDB for the historical races of a player using the playerrace data point.
---
---For specific uses only.
---@param resolvedPageName string
---@return table[]
function StarcraftPlayerExt.fetchRaceHistory(resolvedPageName)
	local conditions = {
		'[[type::playerrace]]',
		'[[pagename::' .. resolvedPageName:gsub(' ', '_') .. ']]',
	}
	local rows = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = table.concat(conditions, ' and '),
		query = 'information, extradata',
	})

	local raceHistory = Array.map(rows, function(row)
		return {
			endDate = row.extradata.enddate,
			race = Faction.read(row.information),
			startDate = row.extradata.startdate,
		}
	end)
	Array.sortInPlaceBy(raceHistory, function(entry) return entry.startDate end)
	return raceHistory
end

---Asks LPDB for the flag and race of a player using an arbitary sample of match2player records.
---
---For specific uses only.
---@param resolvedPageName string
---@return {flag: string?, race: string}
StarcraftPlayerExt.fetchMatch2Player = FnUtil.memoize(function(resolvedPageName)
	local conditions = {
		'[[name::' .. resolvedPageName .. ']]',
	}
	local records = mw.ext.LiquipediaDB.lpdb('match2player', {
		conditions = table.concat(conditions, ' and '),
		limit = 30,
		query = 'flag, extradata',
	})
	local flags = Array.map(records, function(record) return record.flag end)
	local races = Array.map(records, function(record) return Faction.read(record.extradata.faction) end)

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
Fills in the flag, race, and pageName of a player if they are missing. Uses
data previously stored in page variables, and failing that, queries LPDB. The
results are saved to page variables for future use. This function mutates the
player argument.

The flag and race of a player are determined first from the arguments, then
page variables, and finally LPDB. The returned race is a single character
string, either 'p' 't' 'z' or 'r', or nil if unspecified.

player.displayName: Required
player.pageName: Will be resolved if not already.
player.race: Either 'p' 't' 'z' 'r' or 'u'. Will look up if nil.
player.flag: A country name like 'Netherlands'. Will look up if nil.
player.pageIsResolved: Indicates that the pageName is resolved (not a redirect)
so it does not need to be resolved again.

options.date: Needed if the player used a different race in the past. Defaults
to the tournament end date or now.
options.fetchPlayer: Whether to use the LPDB player record. Enabled by default.
options.fetchMatch2Player: Whether to use the player's recent matches. Disabled by default.
options.savePageVar: Whether to save results to page variables. Enabled by default.
]]
---@param player StarcraftStandardPlayer
---@param options {fetchPlayer: boolean, fetchMatch2Player: boolean, savePageVar: boolean, date: string|number|osdate?}?
---@return StarcraftStandardPlayer
function StarcraftPlayerExt.syncPlayer(player, options)
	options = options or {}

	local function match2Player()
		return options.fetchMatch2Player
			and StarcraftPlayerExt.fetchMatch2Player(player.pageName)
			or nil
	end

	PlayerExt.populatePageName(player)

	player.flag = player.flag
		or String.nilIfEmpty(Flags.CountryName(globalVars:get(player.displayName .. '_flag')))
		or options.fetchPlayer ~= false and StarcraftPlayerExt.fetchPlayerFlag(player.pageName)
		or match2Player() and match2Player().flag

	player.race = player.race
		or globalVars:get(player.displayName .. '_race')
		or options.fetchPlayer ~= false and StarcraftPlayerExt.fetchPlayerRace(player.pageName, options.date)
		or match2Player() and match2Player().race
		or Faction.defaultFaction

	if options.savePageVar ~= false then
		StarcraftPlayerExt.saveToPageVars(player)
	end

	return player
end

---Same as StarcraftPlayerExt.syncPlayer, except it does not save the player's flag and race to page variables.
---@param player StarcraftStandardPlayer
---@param options {fetchPlayer: boolean, fetchMatch2Player: boolean, savePageVar: boolean, date: string?}?
---@return StarcraftStandardPlayer
function StarcraftPlayerExt.populatePlayer(player, options)
	return StarcraftPlayerExt.syncPlayer(player, Table.merge(options, {savePageVar = false}))
end

---Saves the pageName, flag, and race of a player to page variables,
---so that editors do not have to duplicate the same info later on.
---@param player StarcraftStandardPlayer
function StarcraftPlayerExt.saveToPageVars(player)
	if player.pageName then
		globalVars:set(player.displayName .. '_page', player.pageName)
	end
	if player.flag then
		globalVars:set(player.displayName .. '_flag', player.flag)
	end
	if player.race and player.race ~= Faction.defaultFaction then
		globalVars:set(player.displayName .. '_race', player.race)
	end
end

return StarcraftPlayerExt
