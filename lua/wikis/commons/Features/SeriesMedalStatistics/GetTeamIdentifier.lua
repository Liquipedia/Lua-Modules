---
-- @Liquipedia
-- page=Module:Features/SeriesMedalStatistics/GetTeamIdentifier
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local GetTeamIdentifier = {}

---@param teams table<string, string>
---@param teamTemplate string
---@return string?
function GetTeamIdentifier.run(teams, teamTemplate)
	if teams[teamTemplate] then
		return teams[teamTemplate]
	end

	local rawData = TeamTemplate.getRawOrNil(teamTemplate)

	if not rawData or not rawData.page then return end

	local identifier = rawData.page:lower()

	Array.forEach(TeamTemplate.queryHistoricalNames(rawData.page), function(template)
		teams[template] = identifier
	end)

	return identifier
end

return GetTeamIdentifier
