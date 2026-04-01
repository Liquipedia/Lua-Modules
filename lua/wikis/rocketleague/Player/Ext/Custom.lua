---
-- @Liquipedia
-- page=Module:Player/Ext/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local playerVars = PageVariableNamespace({namespace = 'Player', cached = true})

local PlayerExt = Lua.import('Module:Player/Ext')

---@class RocketleaguePlayerExt: PlayerExt
local PlayerExtCustom = Table.copy(PlayerExt)

--- Asks LPDB for the team a player belonged to on a page. For specific uses only.
---@param resolvedPageName string
---@param date string|number|osdate?
---@return {joinDate: string|number|osdate?, leaveDate: string|number|osdate?, template: string}?
function PlayerExtCustom._fetchTeamFromPlacement(resolvedPageName, date)
	if Logic.isEmpty(resolvedPageName) then
		return
	end
	local conditions = {
		'[[opponenttype::solo]]', -- can not use Opponent.solo due to circular requires
		'[[pagename::' .. mw.title.getCurrentTitle().text:gsub(' ', '_') .. ']]',
		'[[opponentname::' .. resolvedPageName .. ']]',
	}
	local placement = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = 1,
		conditions = table.concat(conditions, ' AND '),
		query = 'opponentplayers',
	})[1] or {}

	local team = (placement.opponentplayers or {}).p1team
	if Logic.isNotEmpty(team) then
		return {
			isTimeless = true,
			template = team:gsub('_', ' '):lower(),
		}
	end
end

--For specific uses only.
---@param resolvedPageName string
---@param date string|number|osdate?
---@return string?
function PlayerExtCustom.fetchTeamTemplate(resolvedPageName, date)
	local entry = PlayerExtCustom._fetchTeamFromPlacement(resolvedPageName, date)
	return entry and TeamTemplate.resolve(entry.template, date) or nil
end

---@param pageName string
---@param template string?
---@param options PlayerExtSyncTeamOptions
---@return string? resolvedTemplate
---@return string? rawTemplate
function PlayerExtCustom.syncTeam(pageName, template, options)
	options = options or {}

	local rawTemplate
	template, rawTemplate = PlayerExt.syncTeam(pageName, template, options)
	if Logic.isNotEmpty(template) or options.fetchPlayer == false then return template, rawTemplate end

	local entry = PlayerExtCustom._fetchTeamFromPlacement(pageName, options.date) --[[@as table]]

	if entry and not entry.isResolved then
		entry.raw = entry.template
		entry.template = entry.template and TeamTemplate.resolve(entry.template, options.date)
		entry.isResolved = true
	end

	local historyVar = playerVars:get(pageName .. '.teamHistory')
	local history = historyVar and Json.parse(historyVar) or {}
	if options.savePageVar ~= false and entry and entry.template then
		if entry.isTimeless then
			history.timeless = entry
		else
			table.insert(history, entry)
			Array.sortInPlaceBy(history, function(e) return e.joinDate end)
		end
		playerVars:set(pageName .. '.teamHistory', Json.stringify(history))
	end

	if not entry then
		return nil
	end
	return entry.template, entry.raw
end

return PlayerExtCustom
