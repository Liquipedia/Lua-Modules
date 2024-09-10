---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Player/Ext/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Flags = require('Module:Flags')
local Faction = require('Module:Faction')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local PlayerExt = Lua.import('Module:Player/Ext')

local globalVars = PlayerExt.globalVars

---@class WarcraftPlayerExt: PlayerExt
local CustomPlayerExt = Table.deepCopy(PlayerExt)
CustomPlayerExt.globalVars = globalVars

---@param resolvedPageName string
---@return {flag: string?, faction: string?, factionHistory: table[]?}?
CustomPlayerExt.fetchPlayer = FnUtil.memoize(function(resolvedPageName)
	local rows = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. resolvedPageName:gsub(' ', '_') .. ']]',
		query = 'nationality, extradata',
	})

	local record = rows[1]
	if record then
		local factionHistory = Logic.readBool(record.extradata.factionhistorical)
			and CustomPlayerExt.fetchFactionHistory(resolvedPageName)
			or nil

		return {
			flag = String.nilIfEmpty(Flags.CountryName(record.nationality)),
			faction = Faction.read(record.extradata.faction),
			factionHistory = factionHistory,
		}
	end
end)

---@param resolvedPageName string
---@param date string|number|osdate?
---@return string?
function CustomPlayerExt.fetchPlayerFaction(resolvedPageName, date)
	local lpdbPlayer = CustomPlayerExt.fetchPlayer(resolvedPageName)
	if lpdbPlayer and lpdbPlayer.factionHistory then
		date = date or DateExt.getContextualDateOrNow()
		local entry = Array.find(lpdbPlayer.factionHistory, function(entry) return date <= entry.endDate end)
		return entry and Faction.read(entry.faction)
	else
		return lpdbPlayer and lpdbPlayer.faction
	end
end

---@param resolvedPageName string
---@return string?
function CustomPlayerExt.fetchPlayerFlag(resolvedPageName)
	local lpdbPlayer = CustomPlayerExt.fetchPlayer(resolvedPageName)
	return lpdbPlayer and String.nilIfEmpty(Flags.CountryName(lpdbPlayer.flag))
end

---@param resolvedPageName string
---@return table[]
function CustomPlayerExt.fetchFactionHistory(resolvedPageName)
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

---@param player WarcraftStandardPlayer
---@param options PlayerExtSyncOptions?
---@return WarcraftStandardPlayer
function CustomPlayerExt.syncPlayer(player, options)
	options = options or {}

	player = PlayerExt.syncPlayer(player, options) --[[@as WarcraftStandardPlayer]]

	player.faction = player.faction
		or globalVars:get(player.displayName .. '_faction')
		or options.fetchPlayer ~= false and CustomPlayerExt.fetchPlayerFaction(player.pageName, options.date)
		or Faction.defaultFaction

	if options.savePageVar ~= false then
		CustomPlayerExt.saveToPageVars(player, {overwritePageVars = options.overwritePageVars})
	end

	return player
end

---Same as PlayerExt.syncPlayer, except it does not save the player's flag to page variables.
---@param player WarcraftStandardPlayer
---@param options PlayerExtPopulateOptions?
---@return WarcraftStandardPlayer
function CustomPlayerExt.populatePlayer(player, options)
	return CustomPlayerExt.syncPlayer(player, Table.merge(options, {savePageVar = false}))
end

---@param player WarcraftStandardPlayer
---@param options {overwritePageVars: boolean}?
function CustomPlayerExt.saveToPageVars(player, options)
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

return CustomPlayerExt
