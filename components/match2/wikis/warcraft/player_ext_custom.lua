---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Player/Ext/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Flags = require('Module:Flags')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Race = require('Module:Race')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local PlayerExt = Lua.import('Module:Player/Ext', {requireDevIfEnabled = true})

local CustomPlayerExt = Table.deepCopy(PlayerExt)

local globalVars = PlayerExt.globalVars

CustomPlayerExt.fetchPlayer = FnUtil.memoize(function(resolvedPageName)
	local rows = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. resolvedPageName:gsub(' ', '_') .. ']]',
		query = 'nationality, extradata',
	})

	local record = rows[1]
	if record then
		local raceHistory = Logic.readBool(record.extradata.racehistorical)
			and CustomPlayerExt.fetchRaceHistory(resolvedPageName)
			or nil

		return {
			flag = String.nilIfEmpty(Flags.CountryName(record.nationality)),
			race = Race.read(record.extradata.race),
			raceHistory = raceHistory,
		}
	end
end)

function CustomPlayerExt.fetchPlayerRace(resolvedPageName, date)
	local lpdbPlayer = CustomPlayerExt.fetchPlayer(resolvedPageName)
	if lpdbPlayer and lpdbPlayer.raceHistory then
		date = date or PlayerExt.getContextualDateOrNow()
		local entry = Array.find(lpdbPlayer.raceHistory, function(entry) return date <= entry.endDate end)
		return entry and Race.read(entry.race)
	else
		return lpdbPlayer and lpdbPlayer.race
	end
end

function CustomPlayerExt.fetchPlayerFlag(resolvedPageName)
	local lpdbPlayer = CustomPlayerExt.fetchPlayer(resolvedPageName)
	return lpdbPlayer and String.nilIfEmpty(Flags.CountryName(lpdbPlayer.flag))
end

function CustomPlayerExt.fetchRaceHistory(resolvedPageName)
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
			race = Race.read(row.information),
			startDate = row.extradata.startdate,
		}
	end)
	Array.sortInPlaceBy(raceHistory, function(entry) return entry.startDate end)
	return raceHistory
end


function CustomPlayerExt.syncPlayer(player, options)
	options = options or {}

	PlayerExt.populatePageName(player)

	player.flag = player.flag
		or String.nilIfEmpty(Flags.CountryName(globalVars:get(player.displayName .. '_flag')))
		or options.fetchPlayer ~= false and CustomPlayerExt.fetchPlayerFlag(player.pageName)

	player.race = player.race
		or globalVars:get(player.displayName .. '_race')
		or options.fetchPlayer ~= false and CustomPlayerExt.fetchPlayerRace(player.pageName, options.date)
		or 'u'

	if options.savePageVar ~= false then
		CustomPlayerExt.saveToPageVars(player)
	end

	return player
end

function CustomPlayerExt.populatePlayer(player, options)
	return CustomPlayerExt.syncPlayer(player, Table.merge(options, {savePageVar = false}))
end

function CustomPlayerExt.saveToPageVars(player)
	if player.race and player.race ~= DEFAULT_RACE then
		globalVars:set(player.displayName .. '_race', player.race)
	end

	PlayerExt.saveToPageVars(player)
end

return CustomPlayerExt
