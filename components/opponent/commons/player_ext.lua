---
-- @Liquipedia
-- wiki=commons
-- page=Module:Player/Ext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Flags = require('Module:Flags')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')

local globalVars = PageVariableNamespace({cached = true})
local playerVars = PageVariableNamespace({namespace = 'Player', cached = true})

---@class PlayerExt
local PlayerExt = {globalVars = globalVars}

---@class PlayerExtSyncOptions: PlayerExtPopulateOptions
---@field savePageVar boolean?
---@field overwritePageVars boolean?

---@class PlayerExtPopulateOptions
---@field fetchPlayer boolean?
---@field fetchMatch2Player boolean?
---@field date string|number|osdate?

--[===[
Splits a wiki link of a player into a pageName and displayName.

For example:
PlayerExt.extractFromLink('[[Dream (Korean Terran player)|Dream]]')
-- returns 'Dream (Korean Terran player)', 'Dream'
--]===]
---@param name string
---@return string? #pageName
---@return string? #displayName
function PlayerExt.extractFromLink(name)
	name = name
		:gsub('%b{}', '')
		:gsub('%b<>', '')
		:gsub('%b[]', '')
	name = mw.text.trim(name)

	local pageName, displayName = unpack(mw.text.split(name, '|', true))
	if displayName and displayName ~= '' then
		return String.nilIfEmpty(pageName), displayName
	end
	return nil, String.nilIfEmpty(name)
end

---Asks LPDB for the flag of a player using the player record.
---
---For specific uses only.
---@param resolvedPageName string
---@return string?
PlayerExt.fetchPlayerFlag = FnUtil.memoize(function(resolvedPageName)
	local rows = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. resolvedPageName:gsub(' ', '_') .. ']]',
		query = 'nationality, extradata',
	})

	local record = rows[1]
	if record then
		return String.nilIfEmpty(Flags.CountryName(record.nationality))
	end
end)

---Asks LPDB for the flag of a player using an arbitary sample of match2player records.
---
---For specific uses only.
---@param resolvedPageName string
---@return {flag: string?}
PlayerExt.fetchMatch2Player = FnUtil.memoize(function(resolvedPageName)
	local conditions = {
		'[[name::' .. resolvedPageName .. ']]',
	}
	local records = mw.ext.LiquipediaDB.lpdb('match2player', {
		conditions = table.concat(conditions, ' and '),
		limit = 30,
		query = 'flag, extradata',
	})
	local flags = Array.map(records, function(record) return record.flag end)

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
	}
end)

--Asks LPDB for the team a player belonged to on a particular date, using the teamhistory data point.
---
---For specific uses only.
---@param resolvedPageName string
---@param date string|number|osdate?
---@return {joinDate: string, leaveDate: string, template: string}?
function PlayerExt.fetchTeamHistoryEntry(resolvedPageName, date)
	date = date or DateExt.getContextualDateOrNow()

	local conditions = {
		'[[type::teamhistory]]',
		'[[pagename::' .. resolvedPageName:gsub(' ', '_') .. ']]',
		'([[extradata_joindate::<' .. date .. ']] or [[extradata_joindate::' .. date .. ']])',
		'[[extradata_joindate::>]]',
		'[[extradata_leavedate::>' .. date .. ']]',
	}
	local records = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = table.concat(conditions, ' and '),
		query = 'information, extradata',
	})
	return records[1] and PlayerExt.teamHistoryEntryFromRecord(records[1])
end

---@param entryRecord datapoint
---@return {joinDate: string, leaveDate: string, template: string}
function PlayerExt.teamHistoryEntryFromRecord(entryRecord)
	return {
		joinDate = entryRecord.extradata.joindate,
		leaveDate = entryRecord.extradata.leavedate,
		template = entryRecord.information:lower(),
	}
end

--For specific uses only.
---@param resolvedPageName string
---@param date string|number|osdate?
---@return string?
function PlayerExt.fetchTeamTemplate(resolvedPageName, date)
	local entry = PlayerExt.fetchTeamHistoryEntry(resolvedPageName, date)
	return entry and TeamTemplate.resolve(entry.template, date) or nil
end

--[[
Fills in the flag and pageName of a player if they are missing. Uses data
previously stored in page variables, and failing that, queries LPDB. The
results are saved to page variables for future use. This function mutates the
player argument.

The flag of a player are determined first from the arguments, then page
variables, and finally LPDB.

player.displayName: Display name of the player. Cannot be nil.
player.pageName: Defaults to the display name. Will be resolved if not already.
player.flag: A country name like 'Netherlands'. Will look up if nil.
player.pageIsResolved: Indicates that the pageName is resolved (not a redirect)
so it does not need to be resolved again.

options.fetchPlayer: Whether to use the LPDB player record. Enabled by default.
options.fetchMatch2Player: Whether to use the player's recent matches. Disabled by default.
options.savePageVar: Whether to save results to page variables. Enabled by default.
]]
---@param player standardPlayer
---@param options PlayerExtSyncOptions?
---@return standardPlayer
function PlayerExt.syncPlayer(player, options)
	options = options or {}

	local function match2Player()
		return options.fetchMatch2Player
			and PlayerExt.fetchMatch2Player(player.pageName)
			or nil
	end

	PlayerExt.populatePageName(player)

	player.flag = player.flag
		or String.nilIfEmpty(Flags.CountryName(globalVars:get(player.displayName .. '_flag')))
		or options.fetchPlayer ~= false and PlayerExt.fetchPlayerFlag(player.pageName)
		or match2Player() and match2Player().flag

	if options.savePageVar ~= false then
		PlayerExt.saveToPageVars(player, {overwritePageVars = options.overwritePageVars})
	end

	return player
end

---Same as PlayerExt.syncPlayer, except it does not save the player's flag to page variables.
---@param player standardPlayer
---@param options PlayerExtPopulateOptions?
---@return standardPlayer
function PlayerExt.populatePlayer(player, options)
	return PlayerExt.syncPlayer(player, Table.merge(options, {savePageVar = false}))
end

---For specific uses only.
---@param player standardPlayer
function PlayerExt.populatePageName(player)
	player.pageName = player.pageIsResolved and player.pageName
		or player.pageName and mw.ext.TeamLiquidIntegration.resolve_redirect(player.pageName)
		or globalVars:get(player.displayName .. '_page')
		or player.displayName and mw.ext.TeamLiquidIntegration.resolve_redirect(player.displayName)

	player.pageIsResolved = player.pageName and true or nil
end

---Saves the pageName and flag of a player to page variables,
---so that editors do not have to duplicate the same info later on.
---@param player standardPlayer
---@param options {overwritePageVars: boolean?}?
function PlayerExt.saveToPageVars(player, options)
	local displayName = player.displayName
	if not displayName then return end

	options = options or {}
	local overwrite = options.overwritePageVars

	if PlayerExt.shouldWritePageVar(displayName .. '_page', player.pageName, overwrite) then
		globalVars:set(displayName .. '_page', player.pageName)
	end
	if PlayerExt.shouldWritePageVar(displayName .. '_flag', player.flag, overwrite) then
		globalVars:set(displayName .. '_flag', player.flag)
	end
end

---@param varName string
---@param input string?
---@param overwrite boolean?
---@return boolean
function PlayerExt.shouldWritePageVar(varName, input, overwrite)
	if not input then
		return false
	elseif overwrite then
		return true
	end

	local varValue = globalVars:get(varName)
	return Logic.isEmpty(varValue)
end

--[[
Fills in the team of the player on the specified date, if it is not specified
in the arguments. The team is determined from previous invocations of
PlayerExt.syncTeam, and then lpdb. The team is stored to page variables for
future use. The returned value is a team template resolved to a specific date,
or nil if the player is teamless or if the team cannot be determined.

pageName: page of the player, and must be resolved (cannot be a redirect).
template: team template, or nil. Specify 'noteam' to clear a previously set team

options.date: Needed if the player was on a different team in the past.
Defaults to the tournament end date or now.
options.fetchPlayer: Whether to look up lpdb records of the player page. Enabled
by default.
options.savePageVar: Whether to save results to page variables. Enabled by
default.
options.useTimeless: Whether to use the template passed to a previous call of
PlayerExt.syncTeam. Enabled by default.
]]
---@param pageName string
---@param template string?
---@param options {date: string|number|osdate?, useTimeless: boolean, fetchPlayer: boolean, savePageVar: boolean}
---@return string?
function PlayerExt.syncTeam(pageName, template, options)
	options = options or {}
	local dateInput = Logic.emptyOr(options.date, DateExt.getContextualDateOrNow())
	---@cast dateInput -nil
	local date = DateExt.toYmdInUtc(dateInput)

	local historyVar = playerVars:get(pageName .. '.teamHistory')
	local history = historyVar and Json.parse(historyVar) or {}
	local pageVarEntry = options.useTimeless ~= false and history.timeless
		or Array.find(history, function(entry) return date < entry.leaveDate end)

	local timelessEntry = template and {
		isResolved = pageVarEntry and template == pageVarEntry.template,
		isTimeless = true,
		template = template ~= 'noteam' and template or nil,
	}

	-- Catch an edge case where pageVarEntry.team is set while pageVarEntry.template is not set
	-- (pageVarEntry.team being an unresolved team template or lowercased underscore replaced pagename of the team)
	if pageVarEntry and not pageVarEntry.template then
		pageVarEntry.template = pageVarEntry.team
		pageVarEntry.isResolved = nil
	end

	local entry = timelessEntry
		or pageVarEntry
		or options.fetchPlayer ~= false and PlayerExt.fetchTeamHistoryEntry(pageName, options.date)

	if entry and not entry.isResolved then
		entry.template = entry.template and TeamTemplate.resolve(entry.template, options.date)
		entry.isResolved = true
	end

	if options.savePageVar ~= false and entry
		and (entry and entry.template) ~= (pageVarEntry and pageVarEntry.template) then
		if entry.isTimeless then
			history.timeless = entry
		else
			table.insert(history, entry)
			Array.sortInPlaceBy(history, function(e) return e.joinDate end)
		end
		playerVars:set(pageName .. '.teamHistory', Json.stringify(history))
	end

	return entry and entry.template or nil
end

---Same as PlayerExt.syncTeam, except it does not save the player's team to page variables.
---@param pageName string
---@param template string?
---@param options {date: string?, useTimeless: boolean, fetchPlayer: boolean}
---@return string?
function PlayerExt.populateTeam(pageName, template, options)
	return PlayerExt.syncTeam(pageName, template, Table.merge(options, {savePageVar = false}))
end

return PlayerExt
