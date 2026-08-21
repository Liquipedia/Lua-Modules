---
-- @Liquipedia
-- page=Module:Features/Squad/Auto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Info = Lua.import('Module:Info')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local RoleUtil = Lua.import('Module:Role/Util')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local TransferRefs = Lua.import('Module:Transfer/References')

local SquadTypes = Lua.import('Module:Features/Squad/Types')
local SquadHistory = Lua.import('Module:Features/Squad/Lib/History')
local SquadTransferHistory = Lua.import('Module:Features/Squad/Api/TransferHistory')
local SquadCustom = Lua.import('Module:Features/Squad/Custom')

local INVALID_HISTORY_CATEGORY = 'SquadAuto with invalid player history'

---@class SquadAuto
---@field args table
---@field config SquadAutoConfig
---@field manualPlayers table?
---@field manualTimeline table?
---@field playersTeamHistory table<string, TeamHistoryEntry[]>
local SquadAuto = Class.new(nil, function (self, frame)
	self.args = Arguments.getArgs(frame)
end)

---@class SquadAutoConfig
---@field team string
---@field status SquadStatus
---@field type SquadType
---@field title string?
---@field teams string[]?

---@class SquadAutoPerson: SquadPersonArgs
---@field roleData RoleData[]
---@field positionData RoleData[]

---Entrypoint for SquadAuto tables
---@param frame Frame|table
---@return Renderable?
function SquadAuto.run(frame)
	if not Info.config.squads.standardizedAuto then
		-- Legacy mode: Call old SquadAuto
		local OldSquadAuto = Lua.import('Module:SquadAuto')
		local args = Arguments.getArgs(frame)

		local type = SquadTypes.TypeToSquadType[(args.type or ''):lower()]
		-- Old module needs special type argument
		if type == SquadTypes.SquadType.STAFF then
			args.type = 'Organization_' .. args.status
		else
			args.type = 'Player_' .. args.status
		end

		return OldSquadAuto[args.status](args)
	end

	local autosquad = SquadAuto(frame)
	local entries = autosquad:build()
	return autosquad:display(entries)
end

---Handles all necessary steps to fetch and sort data
function SquadAuto:build()
	self:_parseConfig()
	self.playersTeamHistory = SquadTransferHistory.forTeam(self.config.team, self.config.teams)
	local entries = self:_selectEntries()
	Array.forEach(entries, FnUtil.curry(SquadAuto._enrichEntry, self))
	return entries
end

---Parses the args into a SquadAutoConfig
---@private
function SquadAuto:_parseConfig()
	local args = self.args
	local type = SquadTypes.TypeToSquadType[(args.type or ''):lower()]
	local status = SquadTypes.StatusToSquadStatus[(args.status or ''):lower()]
	self.config = {
		team = args.team or mw.title.getCurrentTitle().text,
		type = type,
		status = status,
		title = args.title
	}

	self.manualPlayers, self.enrichmentInfo = self:_readManualRowInput()

	-- Override default 'Former Squad' title
	if status == SquadTypes.SquadStatus.FORMER
			and type == SquadTypes.SquadType.PLAYER
			and not self.config.title then
		self.config.title = 'Former Players'
	end

	local historicalTemplates = TeamTemplate.queryHistorical(self.config.team) or {}
	self.config.teams = Array.append(Array.extractValues(historicalTemplates), TeamTemplate.resolve(self.config.team))

	if Logic.isEmpty(self.config.teams) then
		error(TeamTemplate.noTeamMessage(self.config.team))
	end
end

---@param entries SquadAutoPerson[]
---@return Renderable?
function SquadAuto:display(entries)
	if Logic.isEmpty(entries) then
		return
	end

	if self:_isStatus(SquadTypes.SquadStatus.FORMER) or self:_isStatus(SquadTypes.SquadStatus.FORMER_INACTIVE) then
		return self:displayTabs(entries)
	end

	local useRankSort = self:_isStatus(SquadTypes.SquadStatus.ACTIVE)
	entries = SquadAuto._sortEntries(entries, useRankSort)

	return SquadCustom.runAuto(entries, self.config.status, self.config.type, self.config.title)
end

---@private
---@param entries SquadAutoPerson[]
---@return Renderable?
function SquadAuto:displayTabs(entries)
	local _, groupedEntries = Array.groupBy(
		entries,
		---@param entry SquadAutoPerson
		function (entry)
			assert(entry.leavedate, "Missing leavedate for " .. (entry.id or entry.name))
			return entry.leavedate:match('(%d%d%d%d)')
		end
	)

	local tabCount = Table.size(groupedEntries)
	if tabCount == 1 then
		return SquadCustom.runAuto(
			SquadAuto._sortEntries(entries),
			self.config.status,
			self.config.type,
			self.config.title
		)
	end

	---@type table<string, integer|boolean|Renderable>
	local tabs = {
		This = tabCount,
		removeEmptyTabs = true
	}

	local idx = 1
	for year, group in Table.iter.spairs(groupedEntries) do
		tabs['name' .. idx] = year
		tabs['content' .. idx] = SquadCustom.runAuto(
			SquadAuto._sortEntries(group),
			self.config.status,
			self.config.type,
			self.config.title
		)
		idx = idx + 1
	end

	return Tabs.dynamic(tabs)
end

---@private
---@param entry SquadAutoPerson
function SquadAuto:_enrichEntry(entry)
	local pagename = Page.pageifyLink(entry.link)
	local enrichment = self.enrichmentInfo[pagename]
	if enrichment then
		Table.mergeInto(entry, enrichment)
	end

	local personInfo = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. pagename .. ']]',
		limit = 1,
		query = 'pagename, nationality, id, name, extradata'
	})[1]

	if personInfo then
		entry.id = Logic.nilIfEmpty(entry.id) or personInfo.id
		entry.flag = Logic.nilIfEmpty(entry.flag) or personInfo.nationality
		entry.name = Logic.nilIfEmpty(entry.name) or personInfo.name
	end

	--TODO: Captain from pagevar set in infobox?
end

---@private
---@return SquadAutoPerson[] manualPersons
---@return table<string, SquadAutoPerson> enrichmentInfo
function SquadAuto:_readManualRowInput()
	---@type SquadAutoPerson[]
	local persons = {}
	local enrichmentInfo = {}

	Array.forEach(self.args, function (entry)
		local person = Json.parseIfString(entry)

		if Logic.isEmpty(person) then
			return
		end

		local link = Page.pageifyLink(person.link or person.id or person.name)
		assert(link, 'Missing identifier or link for SquadAutoRow ' .. entry)

		if self:_isStaffTable() and Logic.isNotEmpty(person.role) then
			-- Only allow manual entries for STAFF (organization) tables
			---@type SquadAutoPerson
			local manualPerson = {
				name = person.name,
				id = person.id,
				link = link,
				flag = person.flag,
				position = person.position,
				role = person.role,
				captain = person.captain,

				newteam = person.newteam,
				newrole = person.newteamrole,

				joindate = person.joindate,
				leavedate = person.leavedate,
				inactivedate = person.inactivedate,
				team = person.role == 'Loan' and person.oldteam or nil,

				-- TODO: (Supported by Squad)
				-- teamrole
				-- newteamrole
				-- newteamdate

				faction = person.faction or person.race,
				race = person.faction or person.race,

				-- Used only by SquadAuto
				roleData = RoleUtil.readRoleArgs(person.role),
				positionData = RoleUtil.readRoleArgs(person.position)
			}
			table.insert(persons, manualPerson)
		else
			-- For PLAYER tables, or when no role is given: Treat as override
			enrichmentInfo[link] = {
				id = person.id,
				captain = Logic.readBoolOrNil(person.captain),
				name = person.name,
				flag = person.flag,
				faction = person.faction or person.race,
			}
		end
	end)

	return persons, enrichmentInfo
end

---@private
---@return SquadAutoPerson[]
function SquadAuto:_selectEntries()
	return Array.filter(
		Array.extend(
			Array.flatMap(
				Array.extractValues(self.playersTeamHistory),
				FnUtil.curry(self._selectPersons, self)
			),
			self.manualPlayers
		),
		--- Selects the appropriate entries based on the role.
		---@param entry SquadAutoPerson
		---@return boolean
		function(entry)
			if self:_isStatus(SquadTypes.SquadStatus.INACTIVE) then
				-- For SquadStatus.INACTIVE the entries are already preselected
				-- and won't have the role set to Inactive.
				-- This also matches manual Squad, where status is inactive and role can e.g. be "On Loan"

				return true
			end

			local roles = Array.extendWith(entry.roleData, entry.positionData)
			local hasStaffRoles = Array.any(roles, function(role)
				return role.type == RoleUtil.ROLE_TYPE.STAFF
					or role.type == RoleUtil.ROLE_TYPE.UNKNOWN -- Unknown roles are assumed to be non-player
			end)

			return self:_isStaffTable() == hasStaffRoles
		end
	)
end

---Turns one person's team history into the squad rows that belong in this table.
---Behavior depends on the current config:
---If the status is (in)active, then at most one entry will be returned
---If the status is former(_inactive), there might be multiple entries returned
---@private
---@param entries TeamHistoryEntry[]
---@return SquadAutoPerson[]
function SquadAuto:_selectPersons(entries)
	local selection = SquadHistory.selectStints(entries, self.config.status)
	if not selection then
		return {}
	end

	SquadAuto._reportInvalidHistory(selection.warnings)

	if selection.hasFormerInactiveEntry then
		-- FORMER_INACTIVE enables the Inactive Date display
		self.config.status = SquadTypes.SquadStatus.FORMER_INACTIVE
	end

	return Array.map(selection.stints, FnUtil.curry(SquadAuto._mapToSquadPerson, self))
end

---Logs the transfers that could not be fitted into a person's history, and categorizes the page.
---@private
---@param warnings SquadHistoryWarning[]
function SquadAuto._reportInvalidHistory(warnings)
	Array.forEach(warnings, function (warning)
		mw.log('Invalid transfer history for player ' .. warning.entry.pagename)
		mw.logObject(warning.entry, warning.reason)
		mw.ext.TeamLiquidIntegration.add_category(INVALID_HISTORY_CATEGORY)
	end)
end

---Maps a stint on the team to a single SquadAutoPerson
---@private
---@param stint SquadStint
---@return SquadAutoPerson
function SquadAuto:_mapToSquadPerson(stint)
	local joinEntry = stint.joinEntry
	local inactiveEntry = stint.inactiveEntry or {}
	local leaveEntry = stint.leaveEntry or {}

	local joinReference = TransferRefs.useReferences(joinEntry.references, joinEntry.date)
	local inactiveReference = TransferRefs.useReferences(inactiveEntry.references, inactiveEntry.date)
	local leaveReference = TransferRefs.useReferences(leaveEntry.references, leaveEntry.date)


	local function attachReference(entry, reference)
		return (entry.dateDisplay or entry.date or '') .. ' ' .. reference
	end

	local joindate = attachReference(joinEntry, joinReference)
	local inactivedate = attachReference(inactiveEntry, inactiveReference)
	local leavedate = attachReference(leaveEntry, leaveReference)

	---@type SquadAutoPerson
	local entry = {
		-- name
		id = leaveEntry.displayname or joinEntry.displayname,
		link = joinEntry.pagename,
		flag = joinEntry.flag,

		position = joinEntry.position,
		role = joinEntry.toRole,

		newteam = leaveEntry.toTeam,
		newteamrole = leaveEntry.toRole,
		newteamdate = leaveEntry.date,

		joindate = joindate,
		joindateref = joinEntry.references,

		inactivedate = String.nilIfEmpty(inactivedate),
		inactivedateref = inactiveEntry.references,

		leavedate = String.nilIfEmpty(leavedate),
		leavedateref = leaveEntry.references,

		-- Injected in SquadController.execute:
		-- status
		-- type

		-- Used as loanedto, loanedtorole:
		team = joinEntry.toRole == 'Loan' and joinEntry.fromTeam or nil,
		teamrole = joinEntry.fromRole,

		-- TODO: Fill for current-inactive transfers
		-- activeteam,
		-- activeteamrole,

		-- From legacy: Prefer faction information from leaveEntry
		faction = leaveEntry.faction or joinEntry.faction,
		race = leaveEntry.faction or joinEntry.faction,
		-- game,

		-- Used only by SquadAuto
		roleData = RoleUtil.readRoleArgs(joinEntry.toRole),
		positionData = RoleUtil.readRoleArgs(joinEntry.position)
	}

	-- On leave: Fetch the next team a person joined
	if Logic.isNotEmpty(leaveEntry) and Logic.isEmpty(entry.newteam) then
		local newTeam, newRole, newDate = SquadTransferHistory.fetchNextTeam(joinEntry.pagename, leaveEntry.date)
		if newTeam then
			entry.newteam = newTeam
			entry.newteamrole = newRole
			entry.newteamdate = newDate
		end
	end

	return entry
end

---Sorts a list of persons
-- Active entries (no leavedate) sorted by joindate,
-- Former entries sorted by leavedate
---@private
---@param entries SquadAutoPerson[]
---@param useRankSort boolean?
---@return SquadAutoPerson[]
function SquadAuto._sortEntries(entries, useRankSort)
	return Array.sortBy(entries, function (element)
		return {
			useRankSort and (element.positionData[1] or {}).sortOrder or 0,
			useRankSort and (element.roleData[1] or {}).sortOrder or 0,
			element.leavedate or element.joindate or '',
			element.id
		}
	end)
end

---Whether the current table is for staff
---@return boolean
function SquadAuto:_isStaffTable()
	return self.config.type == SquadTypes.SquadType.STAFF
end

---Whether the current table is for a specific status
---@param status SquadStatus
---@return boolean
function SquadAuto:_isStatus(status)
	return self.config.status == status
end

return SquadAuto
