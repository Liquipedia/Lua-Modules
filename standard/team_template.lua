---
-- @Liquipedia
-- wiki=commons
-- page=Module:TeamTemplate
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')

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
function TeamTemplate.resolve(template, date)
	template = template:gsub('_', ' ')
	local raw = mw.ext.TeamTemplate.raw(template, date)
	return raw and raw.templatename
end

--- Retrieves the lightmode image and darkmode image for a given team template.
---@param template string
---@return string?
---@return string?
function TeamTemplate.getIcon(template)
	local raw = mw.ext.TeamTemplate.raw(template)
	if raw then
		local icon = Logic.emptyOr(raw.image, raw.legacyimage)
		local iconDark = Logic.emptyOr(raw.imagedark, raw.legacyimagedark)
		return icon, iconDark
	end
end

--[[
Returns the resolved page name of a team template that has been resolved to a
date. Returns nil if the team does not exist, or if the page is not specified.
]]
TeamTemplate.getPageName = FnUtil.memoize(function(resolvedTemplate)
	local raw = mw.ext.TeamTemplate.raw(resolvedTemplate)
	return raw and mw.ext.TeamLiquidIntegration.resolve_redirect(raw.page)
end)

--[[
Returns raw data of a team template for a team on a given date. Throws if the
team template does not exist.
The team can be specified using a team page name, team template, or alias.
]]
function TeamTemplate.getRaw(team, date)
	return TeamTemplate.getRawOrNil(team, date)
		or error(TeamTemplate.noTeamMessage(team, date), 2)
end

--[[
Same as TeamTemplate.getRaw, except that it returns nil if the team template
does not exist.
]]
function TeamTemplate.getRawOrNil(team, date)
	team = team:gsub('_', ' '):lower()
	return mw.ext.TeamTemplate.raw(team, date)
end

function TeamTemplate.noTeamMessage(pageName, date)
	return 'Missing template for team=' .. tostring(pageName)
		.. (date and ' on date=' .. tostring(date) or '')
end

return TeamTemplate
