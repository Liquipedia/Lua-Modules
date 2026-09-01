---
-- @Liquipedia
-- page=Module:Features/Squad/Auto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
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
local SquadCustom = Lua.import('Module:Features/Squad/Custom')
local SquadTransferHistory = Lua.import('Module:Features/Squad/Api/TransferHistory')

local INVALID_HISTORY_CATEGORY = 'SquadAuto with invalid player history'

---@class SquadAuto
---@field args table
---@field config SquadAutoConfig
---@field manualPlayers table?
---@field manualTimeline table?
---@field playersTeamHistory table<string, TeamHistoryEntry[]>
local SquadAuto = {}

---@class SquadAutoConfig
---@field team string
---@field status SquadStatus
---@field type SquadType
---@field title string?
---@field teams string[]?

---@class SquadAutoPerson: SquadPersonArgs
---@field roleData RoleData[]
---@field positionData RoleData[]

---Parses the args into a SquadAutoConfig
function SquadAuto._parseConfig(args)
	local type = SquadTypes.TypeToSquadType[(args.type or ''):lower()]
	local status = SquadTypes.StatusToSquadStatus[(args.status or ''):lower()]
	local config = {
		team = args.team or mw.title.getCurrentTitle().text,
		type = type,
		status = status,
		title = args.title
	}

	-- Override default 'Former Squad' title
	if status == SquadTypes.SquadStatus.FORMER
			and type == SquadTypes.SquadType.PLAYER
			and not config.title then
		config.title = 'Former Players'
	end

	local historicalTemplates = TeamTemplate.queryHistorical(config.team) or {}
	config.teams = Array.append(Array.extractValues(historicalTemplates), TeamTemplate.resolve(config.team))


	if Logic.isEmpty(config.teams) then
		error(TeamTemplate.noTeamMessage(config.team))
	end

	return config
end

---@param entries SquadAutoPerson[]
---@return Renderable?
function SquadAuto.display(config, entries)
	if SquadAuto._isStatus(config, SquadTypes.SquadStatus.FORMER) or SquadAuto._isStatus(config, SquadTypes.SquadStatus.FORMER_INACTIVE) then
		return SquadAuto.displayTabs(config, entries)
	end

	local useRankSort = SquadAuto._isStatus(config, SquadTypes.SquadStatus.ACTIVE)
	entries = SquadAuto._sortEntries(entries, useRankSort)

	return SquadCustom.runAuto(entries, config.status, config.type, config.title)
end

---@private
---@param entries SquadAutoPerson[]
---@return Renderable?
function SquadAuto.displayTabs(config, entries)
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
			config.status,
			config.type,
			config.title
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
			config.status,
			config.type,
			config.title
		)
		idx = idx + 1
	end

	return Tabs.dynamic(tabs)
end

---@param entry SquadAutoPerson
function SquadAuto._enrichEntry(enrichmentInfo, entry)
	local pagename = Page.pageifyLink(entry.link)
	local enrichment = enrichmentInfo[pagename]
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

---@return SquadAutoPerson[] manualPersons
---@return table<string, SquadAutoPerson> enrichmentInfo
function SquadAuto._readManualRowInput(args, config)
	---@type SquadAutoPerson[]
	local persons = {}
	local enrichmentInfo = {}

	Array.forEach(args, function (entry)
		local person = Json.parseIfString(entry)

		if Logic.isEmpty(person) then
			return
		end

		local link = Page.pageifyLink(person.link or person.id or person.name)
		assert(link, 'Missing identifier or link for SquadAutoRow ' .. entry)

		if SquadAuto._isStaffTable(config) and Logic.isNotEmpty(person.role) then
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

---@return SquadAutoPerson[]
function SquadAuto._selectEntries(playersTeamHistory, manualPlayers, config)
	return Array.filter(
		Array.extend(
			Array.flatMap(
				Array.extractValues(playersTeamHistory),
				FnUtil.curry(SquadAuto._selectPersons, config)
			),
			manualPlayers
		),
		--- Selects the appropriate entries based on the role.
		---@param entry SquadAutoPerson
		---@return boolean
		function(entry)
			if SquadAuto._isStatus(config, SquadTypes.SquadStatus.INACTIVE) then
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

			return SquadAuto._isStaffTable(config) == hasStaffRoles
		end
	)
end

---Turns one person's team history into the squad rows that belong in this table.
---Behavior depends on the current config:
---If the status is (in)active, then at most one entry will be returned
---If the status is former(_inactive), there might be multiple entries returned
---@private
---@param config SquadAutoConfig
---@param entries TeamHistoryEntry[]
---@return SquadAutoPerson[]
function SquadAuto._selectPersons(config, entries)
	local selection = SquadHistory.selectStints(entries, config.status)
	if not selection then
		return {}
	end

	SquadAuto._reportInvalidHistory(selection.warnings)

	if selection.hasFormerInactiveEntry then
		-- FORMER_INACTIVE enables the Inactive Date display
		config.status = SquadTypes.SquadStatus.FORMER_INACTIVE
	end

	return Array.map(selection.stints, SquadAuto._mapToSquadPerson)
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
function SquadAuto._mapToSquadPerson(stint)
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
function SquadAuto._isStaffTable(config)
	return config.type == SquadTypes.SquadType.STAFF
end

---Whether the current table is for a specific status
---@param status SquadStatus
---@return boolean
function SquadAuto._isStatus(config, status)
	return config.status == status
end

return SquadAuto
