---
-- @Liquipedia
-- page=Module:Service/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
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
---@field members table[]

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
---@param date string|number|nil
---@return table[]
function TeamService.getSquadOn(team, date)
	local timestamp = DateExt.readTimestamp(date) or DateExt.readTimestamp(DateExt.getContextualDateOrNow())
	local members = team.members or {}
	return Array.filter(members, function(member)
		local joinDate = DateExt.readTimestamp(member.joindate)
		local leaveDate = DateExt.readTimestamp(member.leavedate)
		local inactiveDate = DateExt.readTimestamp(member.inactivedate)

		-- Bad data
		if not joinDate or DateExt.isDefaultTimestamp(joinDate) then
			return false
		end

		-- Joined after the requested date
		if joinDate > timestamp then
			return false
		end

		-- Bad data
		if not leaveDate then
			return false
		end

		-- Left before the requested date
		if not DateExt.isDefaultTimestamp(leaveDate) and leaveDate < timestamp then
			return false
		end

		-- Went inactive before the requested date
		if inactiveDate and not DateExt.isDefaultTimestamp(inactiveDate) and inactiveDate < timestamp then
			return false
		end

		return true
	end)
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

			joindate = record.joindate,
			leavedate = record.leavedate,
			inactivedate = record.inactivedate,

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
