---
-- @Liquipedia
-- page=Module:Service/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
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
---@field members StandardTeamMember[]

---@class StandardTeamMember
---@field displayName string
---@field pageName string
---@field realName string?
---@field nationality string?
---@field role string?
---@field type string
---@field status any
---@field joindate string?
---@field leavedate string?
---@field inactivedate string?
---@field faction string?
---@field group string
---@field hasLeft boolean?

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

--- Gets the squad of a team between two dates, usually for tournaments
---@param team StandardTeam
---@param startDate string|number
---@param endDate string|number
---@return StandardTeamMember[]
function TeamService.getSquadBetween(team, startDate, endDate)
	assert(startDate and endDate, 'TeamService.getSquadBetween: Start date and end date are required')

	local startTimestamp = DateExt.readTimestamp(startDate)
	local endTimestamp = DateExt.readTimestamp(endDate)

	assert(startTimestamp and endTimestamp, 'TeamService.getSquadBetween: Could not read start date or end date')

	local members = team.members or {}
	local filteredMembers = Array.filter(members, function(member)
		local joinDate = DateExt.readTimestamp(member.joindate)
		local leaveDate = DateExt.readTimestamp(member.leavedate)
		local inactiveDate = DateExt.readTimestamp(member.inactivedate)

		-- Bad data
		if not joinDate or DateExt.isDefaultTimestamp(joinDate) then
			return false
		end

		-- Joined after the end date
		if joinDate > endTimestamp then
			return false
		end

		-- Bad data
		if not leaveDate then
			return false
		end

		-- Left before the start date
		if not DateExt.isDefaultTimestamp(leaveDate) and leaveDate < startTimestamp then
			return false
		end

		-- Went inactive before the start date
		if inactiveDate and not DateExt.isDefaultTimestamp(inactiveDate) and inactiveDate < startTimestamp then
			return false
		end

		return true
	end)

	return Array.map(filteredMembers, function(member)
		member.hasLeft = false
		local leaveDate = DateExt.readTimestamp(member.leavedate)
		local inactiveDate = DateExt.readTimestamp(member.inactivedate)

		-- Bad data check
		if not inactiveDate or not leaveDate then
			return member
		end

		if not DateExt.isDefaultTimestamp(inactiveDate) and inactiveDate < endTimestamp then
			member.hasLeft = true
		elseif not DateExt.isDefaultTimestamp(leaveDate) and leaveDate < endTimestamp then
			member.hasLeft = true
		end

		return member
	end)
end

---@param team StandardTeam
---@return StandardTeamMember[]
function TeamService.getMembers(team)
	local records = mw.ext.LiquipediaDB.lpdb('squadplayer', {
		conditions = '[[pagename::' .. team.pageName .. ']]',
		limit = 5000,
	})
	return Array.map(records, function(record)
		local extradata = record.extradata or {}
		---@type StandardTeamMember
		return {
			displayName = record.id,
			pageName = record.link,
			realName = record.name,
			nationality = record.nationality,
			role = Logic.emptyOr(record.role, record.position),
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
