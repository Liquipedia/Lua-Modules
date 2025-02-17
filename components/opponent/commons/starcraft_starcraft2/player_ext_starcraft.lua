---
-- @Liquipedia
-- wiki=commons
-- page=Module:Player/Ext/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
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

---Asks LPDB for the faction and flag of a player using the player record.
---
---For specific uses only.
---@param resolvedPageName string
---@return {flag: string?, faction: string?, factionHistory: table[]?}?
StarcraftPlayerExt.fetchPlayer = FnUtil.memoize(function(resolvedPageName)
	local rows = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. resolvedPageName:gsub(' ', '_') .. ']]',
		query = 'nationality, extradata',
	})

	local record = rows[1]
	if record then
		local factionHistory = Logic.readBool(record.extradata.factionhistorical)
			and StarcraftPlayerExt.fetchFactionHistory(resolvedPageName)
			or nil

		return {
			flag = String.nilIfEmpty(Flags.CountryName(record.nationality)),
			faction = Faction.read(record.extradata.faction),
			factionHistory = factionHistory,
		}
	end
end)

---For specific uses only.
---@param resolvedPageName string
---@param date string|number|osdate?
---@return string?
function StarcraftPlayerExt.fetchPlayerFaction(resolvedPageName, date)
	local lpdbPlayer = StarcraftPlayerExt.fetchPlayer(resolvedPageName)
	if lpdbPlayer and lpdbPlayer.factionHistory then
		local timestamp = DateExt.readTimestamp(date or DateExt.getContextualDateOrNow())
		---@cast timestamp -nil
		-- convert date to iso format to match the dates retrieved from the data points
		-- need the time too so the below check remains the same as before
		date = DateExt.formatTimestamp('Y-m-d H:i:s', timestamp)
		local entry = Array.find(lpdbPlayer.factionHistory, function(entry) return date <= entry.endDate end)
		return entry and Faction.read(entry.faction)
	else
		return lpdbPlayer and lpdbPlayer.faction
	end
end

---For specific uses only.
---@param resolvedPageName string
---@return string?
function StarcraftPlayerExt.fetchPlayerFlag(resolvedPageName)
	local lpdbPlayer = StarcraftPlayerExt.fetchPlayer(resolvedPageName)
	return lpdbPlayer and String.nilIfEmpty(Flags.CountryName(lpdbPlayer.flag))
end

---Asks LPDB for the historical factions of a player using the player faction data point.
---
---For specific uses only.
---@param resolvedPageName string
---@return table[]
function StarcraftPlayerExt.fetchFactionHistory(resolvedPageName)
	local conditions = {
		'[[type::playerrace]]',
		'[[pagename::' .. resolvedPageName:gsub(' ', '_') .. ']]',
	}
	local rows = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = table.concat(conditions, ' and '),
		query = 'information, extradata',
	})

	local factionHistory = Array.map(rows, function(row)
		return {
			endDate = row.extradata.enddate,
			faction = Faction.read(row.information),
			startDate = row.extradata.startdate,
		}
	end)
	Array.sortInPlaceBy(factionHistory, function(entry) return entry.startDate end)
	return factionHistory
end

---Asks LPDB for the flag and faction of a player using an arbitary sample of match2player records.
---
---For specific uses only.
---@param resolvedPageName string
---@return {flag: string?, faction: string}
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
	local factions = Array.map(records, function(record) return Faction.read(record.extradata.faction) end)

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
		faction = majority(factions),
	}
end)

--[[
Fills in the flag, faction, and pageName of a player if they are missing. Uses
data previously stored in page variables, and failing that, queries LPDB. The
results are saved to page variables for future use. This function mutates the
player argument.

The flag and faction of a player are determined first from the arguments, then
page variables, and finally LPDB. The returned faction is a single character
string, either 'p' 't' 'z' or 'r', or nil if unspecified.

player.displayName: Required
player.pageName: Will be resolved if not already.
player.faction: Either 'p' 't' 'z' 'r' or 'u'. Will look up if nil.
player.flag: A country name like 'Netherlands'. Will look up if nil.
player.pageIsResolved: Indicates that the pageName is resolved (not a redirect)
so it does not need to be resolved again.

options.date: Needed if the player used a different faction in the past. Defaults
to the tournament end date or now.
options.fetchPlayer: Whether to use the LPDB player record. Enabled by default.
options.fetchMatch2Player: Whether to use the player's recent matches. Disabled by default.
options.savePageVar: Whether to save results to page variables. Enabled by default.
]]

---@param player StarcraftStandardPlayer
---@param options PlayerExtSyncOptions?
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

	player.faction = player.faction
		or globalVars:get(player.displayName .. '_faction')
		or options.fetchPlayer ~= false and StarcraftPlayerExt.fetchPlayerFaction(player.pageName, options.date)
		or match2Player() and match2Player().faction
		or Faction.defaultFaction

	if options.savePageVar ~= false then
		StarcraftPlayerExt.saveToPageVars(player, {overwritePageVars = options.overwritePageVars})
	end

	return player
end

---Same as StarcraftPlayerExt.syncPlayer, except it does not save the player's flag and faction to page variables.
---@param player StarcraftStandardPlayer
---@param options PlayerExtPopulateOptions?
---@return StarcraftStandardPlayer
function StarcraftPlayerExt.populatePlayer(player, options)
	return StarcraftPlayerExt.syncPlayer(player, Table.merge(options, {savePageVar = false}))
end

---Saves the pageName, flag, and faction of a player to page variables,
---so that editors do not have to duplicate the same info later on.
---@param player StarcraftStandardPlayer
---@param options {overwritePageVars: boolean}?
function StarcraftPlayerExt.saveToPageVars(player, options)
	local displayName = player.displayName
	if not displayName then return end

	options = options or {}
	local overwrite = options.overwritePageVars

	if PlayerExt.shouldWritePageVar(displayName .. '_faction', player.faction, overwrite)
		and player.faction ~= Faction.defaultFaction then
			globalVars:set(displayName .. '_faction', player.faction)
	end

	PlayerExt.saveToPageVars(player, options)
end

---@param frame Frame
function StarcraftPlayerExt.TemplateStorePlayerLink(frame)
	local args = Arguments.getArgs(frame)

	if not args[1] then return end

	local pageName, displayName = PlayerExt.extractFromLink(args[1])

	StarcraftPlayerExt.saveToPageVars({
		displayName = displayName,
		pageName = args.link or pageName or displayName,
		flag = String.nilIfEmpty(Flags.CountryName(args.flag)),
		faction = Faction.read(args.faction or args.race) or Faction.defaultFaction,
	}, {overwritePageVars = true})
end

return StarcraftPlayerExt
