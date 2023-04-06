---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Player/Ext/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')

local playerVars = PageVariableNamespace({namespace = 'Player', cached = true})

local PlayerExt = Lua.import('Module:Player/Ext', {requireDevIfEnabled = true})

local CustomPlayerExt = Table.deepCopy(PlayerExt)

--[[
Asks LPDB for the team a player belonged to on a page.

For specific uses only.
]]
function CustomPlayerExt.fetchTeamHistoryEntry(resolvedPageName, date)
	if Logic.isEmpty(resolvedPageName) then
		return
	end

	local conditions = {
		'[[type::Notable]]',
		'[[pagename::' .. mw.title.getCurrentTitle().text:gsub(' ', '_') .. ']]',
		'[[name::' .. resolvedPageName .. ']]',
	}
	local datapoint = mw.ext.LiquipediaDB.lpdb('datapoint', {
		limit = 1,
		conditions = table.concat(conditions, ' AND '),
		query = 'information',
	})[1]

	if datapoint and Logic.isNotEmpty(datapoint.information) then
		return {
			joinDate = date,
			leaveDate = date,
			template = datapoint.information:lower(),
		}
	end
end

--- Fills in the team of the player on the specified date, if it is not specified in the arguments.
---@pageName string
---@template string?
---@options {date: string?, fetchPlayer: boolean?, savePageVar: boolean?, useTimeless: boolean?}
function CustomPlayerExt.syncTeam(pageName, template, options)
	options = options or {}
	local date = options.date or PlayerExt.getContextualDateOrNow()

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
		or options.fetchPlayer ~= false and CustomPlayerExt.fetchTeamHistoryEntry(pageName, options.date)

	if entry and not entry.isResolved then
		entry.template = entry.template and TeamTemplate.resolve(entry.template, options.date)
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

return CustomPlayerExt
