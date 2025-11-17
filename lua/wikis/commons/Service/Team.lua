---
-- @Liquipedia
-- page=Module:Service/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local TeamService = {}

---@class StandardTeam
---@field pageName string
---@field fullName string?
---@field bracketName string?
---@field shortName string?
---@field image string?
---@field imageDark string?
---@field members table[]?

--- TODO: Add the rest and implement the lazy loading
local LPDB_TEAM_FIELDS = {
	'links',
}

---Fetches a standings table from a page. Tries to read from page variables before fetching from LPDB.
---@param teamTemplate string
---@return StandardTeam?
function TeamService.getTeamByTemplate(teamTemplate)
	if not teamTemplate or not mw.ext.TeamTemplate.teamexists(teamTemplate) then
		return nil
	end

	local team = mw.ext.TeamTemplate.raw(teamTemplate)

	if not team then
		return nil
	end
	return TeamService.teamFromRecord(team)
end

---@param team StandardTeam
---@return table[]
function TeamService.getMembers(team)
	local records = mw.ext.LiquipediaDB.lpdb('squadplayer', {
		conditions = '[[pagename::' .. team.pageName .. ']]',
		limit = 5000,
	})
	return Array.map(records, function(record)
		local extradata = record.extradata or {}
		return {
			displayName = record.id,
			pageName = record.link,
			realName = record.name,
			nationality = record.nationality,
			position = record.position,
			role = record.role,
			type = record.type,
			status = record.status,
			faction = extradata.faction,
			group = extradata.group or 'main',
		}
	end)
end

local TeamMT = {
	-- Lazy loading of properties to avoid unnecessary database queries.
	__index = function(team, property)
		if property == 'members' then
			team[property] = TeamService.getMembers(team)
		elseif Table.includes(LPDB_TEAM_FIELDS, property) then
			error('Not yet implmented')
		end
		return rawget(team, property)
	end
}

---@param record teamTemplateData
---@return StandardTeam
function TeamService.teamFromRecord(record)
	local team = {
		pageName = Page.pageifyLink(record.page),
		fullName = record.name,
		bracketName = record.bracketname,
		shortName = record.shortname,
		image = record.image,
		imageDark = record.imagedark,
	}

	-- Lazy loading of other properties
	setmetatable(team, TeamMT)

	return team
end

return TeamService
