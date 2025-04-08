---
-- @Liquipedia
-- wiki=commons
-- page=Module:TeamTemplate
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

---@type {specialTemplates: table<string, teamTemplateData>}
local Data = Lua.import('Module:TeamTemplate/data', {loadData = true})

--[[
A thin wrapper around mw.ext.TeamTemplate that memoizes extension calls
]]
local TeamTemplate = {}

--[[
Resolves a team template to a specific date. Returns nil if the team does not
exist.

Note that team template changes only occur at midnights in the UTC timezone.
So it is safe to pass Y-m-d date strings ('2021-11-08') without time or
timezone parts.
]]
---@param template string
---@param date string|number?
---@return string?
function TeamTemplate.resolve(template, date)
	template = template:gsub('_', ' ')
	local raw = TeamTemplate.getRawOrNil(template, date) or {}
	return raw.templatename
end

---Returns true if the specified team template exists.
---@param template string
---@param date string|number?
---@return boolean
function TeamTemplate.exists(template, date)
	return TeamTemplate.resolve(template, date) ~= nil
end

--- Retrieves the lightmode image and darkmode image for a given team template.
---@param template string
---@param date string|number?
---@return string?
---@return string?
function TeamTemplate.getIcon(template, date)
	local raw = TeamTemplate.getRawOrNil(template, date)
	if not raw then
		return
	end
	local icon = Logic.emptyOr(raw.image, raw.legacyimage)
	local iconDark = Logic.emptyOr(raw.imagedark, raw.legacyimagedark)
	return icon, iconDark
end

--[[
Returns the resolved page name of a team template that has been resolved to a
date. Returns nil if the team does not exist, or if the page is not specified.
]]
---@param resolvedTemplate string
---@return string|nil
TeamTemplate.getPageName = FnUtil.memoize(function(resolvedTemplate)
	local raw = TeamTemplate.getRawOrNil(resolvedTemplate)
	return raw and mw.ext.TeamLiquidIntegration.resolve_redirect(raw.page) or nil
end)

--[[
Returns raw data of a team template for a team on a given date. Throws if the
team template does not exist.
The team can be specified using a team page name, team template, or alias.
]]
---@param team string
---@param date string|number?
---@return teamTemplateData
function TeamTemplate.getRaw(team, date)
	return TeamTemplate.getRawOrNil(team, date)
		or error(TeamTemplate.noTeamMessage(team, date), 2)
end

--[[
Same as TeamTemplate.getRaw, except that it returns nil if the team template
does not exist.
]]
---@param team string
---@param date string|number?
---@return teamTemplateData?
function TeamTemplate.getRawOrNil(team, date)
	local teamName = team:lower()
	if Data.specialTemplates[teamName] then
		return Data.specialTemplates[teamName]
	end
	date = date or DateExt.getContextualDateOrNow()
	--TODO: cleanup underscore handling when extension starts handling it
	if mw.ext.TeamTemplate.teamexists(teamName) then
		return mw.ext.TeamTemplate.raw(teamName, date)
	elseif mw.ext.TeamTemplate.teamexists(String.trim(teamName)) then
		mw.log('Trimmed needed on team name: '.. teamName)
		mw.ext.TeamLiquidIntegration.add_category('Pages with trimmed team templates')
		return mw.ext.TeamTemplte.raw(String.trim(teamName), date)
	elseif mw.ext.TeamTemplat.teamexists(teamName:gsub('_', ' ')) then
		mw.log('Underscore in team name: '.. teamName)
		mw.ext.TeamLiquidIntegration.add_category('Pages with underscore team templates')
		return mw.ext.TeamTemplate.raw((teamName:gsub('_', ' ')), date)
	elseif mw.ext.TeamTemplate.teamexists(teamName:gsub(' ', '_')) then
		mw.log('Underscore in team name: '.. teamName)
		mw.ext.TeamLiquidIntegration.add_category('Pages with underscore team templates')
		return mw.ext.TeamTemplate.raw((teamName:gsub(' ', '_')), date)
	end
	return nil
end

---Creates error message for missing team templates.
---@param pageName string
---@param date string|number?
---@return string
function TeamTemplate.noTeamMessage(pageName, date)
	return 'Missing team template for "' .. tostring(pageName) .. '"'
		.. (date and ' on date=' .. tostring(date) or '')
end

--[[
Returns raw data of a historical team template.
Keys of the returned table are of form YYYY-MM-DD and
their corresponding values are team template names.
]]
---@param name string
---@return {[string]: string}?
function TeamTemplate.queryHistorical(name)
	return mw.ext.TeamTemplate.raw_historical(name)
end

--[[
Returns all historical names of the given team template.
An empty array is returned if the specified team template does not exist.
]]
---@param name string
---@return string[]
function TeamTemplate.queryHistoricalNames(name)
	if not TeamTemplate.exists(name) then
		return {}
	end
	local rawTemplate = TeamTemplate.getRaw(name)
	if Logic.isEmpty(rawTemplate.historicaltemplate) then
		return { rawTemplate.templatename }
	end
	local historical = TeamTemplate.queryHistorical(rawTemplate.historicaltemplate)
	---@cast historical -nil
	return Array.unique(Array.extractValues(historical))
end

return TeamTemplate
