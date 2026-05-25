---
-- @Liquipedia
-- page=Module:Squad/Auto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Condition = Lua.import('Module:Condition')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Operator = Lua.import('Module:Operator')
local Page = Lua.import('Module:Page')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local RoleUtil = Lua.import('Module:Role/Util')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local TransferRefs = Lua.import('Module:Transfer/References')

local SquadUtils = Lua.import('Module:Squad/Utils')
local SquadCustom = Lua.import('Module:Squad/Custom')

local SquadAutoRank = Lua.import('Module:SquadAuto/rank', {loadData=true})

local BooleanOperator = Condition.BooleanOperator
local Comparator = Condition.Comparator

local pageVars = PageVariableNamespace()

---@class SquadAuto
---@field args table
---@field config SquadAutoConfig
---@field manualPlayers table?
---@field manualTimeline table?
---@field playersTeamHistory table<string, TeamHistoryEntry[]>
local SquadAuto = Class.new(nil, function (self, frame)
	self.args = Arguments.getArgs(frame)
end)

---@class SquadAutoTeam
---@field team string
---@field role string?
---@field position string?
---@field date string?

---@class SquadAutoConfig
---@field team string
---@field status SquadStatus
---@field type SquadType
---@field title string?
---@field teams string[]?

---@enum TransferType
SquadAuto.TransferType = {
	LEAVE = 'LEAVE',
	JOIN = 'JOIN',
	CHANGE = 'CHANGE',
}

---@class (exact) TeamHistoryEntry
---@field pagename string
---@field displayname string
---@field flag string
---@field date string
---@field dateDisplay string
---@field type TransferType
---@field references table<string, string>
---@field wholeTeam boolean
---@field position string
---@field fromTeam string?
---@field fromRole string?
---@field toTeam string?
---@field toRole string?
---@field faction string?

---@enum TransferSide
local Side = {
	from = 'from',
	to = 'to',
}

-- Default key for SquadAuto/rank
local DEFAULT_RANK_KEY = ''

local ROLE_INACTIVE = 'Inactive'

---Entrypoint for SquadAuto tables
---@param frame Frame|table
---@return Widget|Html|string?
function SquadAuto.run(frame)
	local autosquad = SquadAuto(frame)
	autosquad:parseConfig()
	autosquad:queryTransfers()

	local entries = autosquad:selectEntries()
	Array.forEach(entries, FnUtil.curry(SquadAuto.enrichEntry, autosquad))

	return autosquad:display(entries)
end

---Parses the args into a SquadAutoConfig
function SquadAuto:parseConfig()
	local args = self.args
	local type = SquadUtils.TypeToSquadType[(args.type or ''):lower()]
	local status = SquadUtils.StatusToSquadStatus[(args.status or ''):lower()]
	self.config = {
		team = args.team or mw.title.getCurrentTitle().text,
		type = type,
		status = status,
		title = args.title
	}

	self.manualPlayers, self.enrichmentInfo = self:readManualRowInput()

	-- Override default 'Former Squad' title
	if status == SquadUtils.SquadStatus.FORMER
			and type == SquadUtils.SquadType.PLAYER
			and not self.config.title then
		self.config.title = 'Former Players'
	end

	local historicalTemplates = TeamTemplate.queryHistorical(self.config.team) or {}
	self.config.teams = Array.append(Array.extractValues(historicalTemplates), TeamTemplate.resolve(self.config.team))

	if Logic.isEmpty(self.config.teams) then
		error(TeamTemplate.noTeamMessage(self.config.team))
	end
end

---@param entries SquadPersonArgs[]
---@return Widget|Html|string?
function SquadAuto:display(entries)
	if Logic.isEmpty(entries) then
		return
	end

	if self.config.status == SquadUtils.SquadStatus.FORMER
		or self.config.status == SquadUtils.SquadStatus.FORMER_INACTIVE then
		return self:displayTabs(entries)
	end

	local useRankSort = self.config.status == SquadUtils.SquadStatus.ACTIVE
	entries = SquadAuto._sortEntries(entries, useRankSort)

	return SquadCustom.runAuto(entries, self.config.status, self.config.type, self.config.title)
end

---@param entries SquadPersonArgs[]
---@return Widget|Html|string?
function SquadAuto:displayTabs(entries)
	local _, groupedEntries = Array.groupBy(
		entries,
		---@param entry SquadPersonArgs
		function (entry)
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

	---@type table<string, any>
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

---@param entry SquadPersonArgs
function SquadAuto:enrichEntry(entry)
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

---@return SquadPersonArgs[] manualPersons
---@return table<string, SquadPersonArgs> enrichmentInfo
function SquadAuto:readManualRowInput()
	---@type SquadPersonArgs[]
	local persons = {}
	local enrichmentInfo = {}

	Array.forEach(self.args, function (entry)
		local person = Json.parseIfString(entry)

		if Logic.isEmpty(person) then
			return
		end

		local link = Page.pageifyLink(person.link or person.id or person.name)
		assert(link, 'Missing identifier or link for SquadAutoRow ' .. entry)

		if self.config.type == SquadUtils.SquadType.STAFF and Logic.isNotEmpty(person.role) then
			-- Only allow manual entries for STAFF (organization) tables
			---@type SquadPersonArgs
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

function SquadAuto:queryTransfers()
	---Checks whether a given team is the currently queried team
	---@param team string?
	---@return boolean
	local function isCurrentTeam(team)
		if not team then
			return false
		end
		return Array.any(self.config.teams, FnUtil.curry(Operator.eq, team))
	end

	---@param side TransferSide
	---@param transfer transfer
	---@return string | nil, boolean
	local function parseRelevantTeam(side, transfer)
		local mainTeam = transfer[side .. 'teamtemplate']
		if mainTeam and isCurrentTeam(mainTeam) then
			return mainTeam, true
		end

		local secondaryTeam = transfer.extradata[side .. 'teamsectemplate']
		if secondaryTeam and isCurrentTeam(secondaryTeam) then
			return secondaryTeam, false
		end

		return nil, false
	end

	---Maps a transfer to a transfertype, with regards to the current team.
	---@param relevantFromTeam string?
	---@param relevantToTeam string?
	---@return TransferType
	local function getTransferType(relevantFromTeam, relevantToTeam)
		if relevantFromTeam then
			if relevantToTeam then
				return SquadAuto.TransferType.CHANGE
			end
			return SquadAuto.TransferType.LEAVE
		end
		return SquadAuto.TransferType.JOIN
	end

	---Parses the relevant role for the current team from a transfer
	---@param side TransferSide
	---@param transfer transfer
	---@param team string?
	---@param isMain boolean
	---@return string?
	local function parseRelevantRole(side, transfer, team, isMain)
		if not team then
			return nil
		end

		if isMain then
			return side == Side.from and transfer.role1 or transfer.role2
		else
			return side == Side.from and transfer.extradata.role1sec or transfer.extradata.role2sec
		end
	end

	local teamHistoryKey = self.config.team .. '_all_transfers'

	---@type table<string, TeamHistoryEntry>
	self.playersTeamHistory = Json.parseIfTable(pageVars:get(teamHistoryKey)) or {}

	if Logic.isNotEmpty(self.playersTeamHistory) then
		return
	end

	Lpdb.executeMassQuery(
		'transfer',
		{
			conditions = self:buildConditions(),
			order = 'date asc, objectname desc',
			limit = 5000
		},
		function(record)
			self.playersTeamHistory[record.player] = self.playersTeamHistory[record.player] or {}
			record.extradata = record.extradata or {}


			local relevantFromTeam, isFromMain = parseRelevantTeam(Side.from, record)
			local relevantToTeam, isToMain = parseRelevantTeam(Side.to, record)
			local transferType = getTransferType(relevantFromTeam, relevantToTeam)

			-- For leave transfers: Pass on new team for display as next team
			if transferType == SquadAuto.TransferType.LEAVE and Logic.isEmpty(relevantToTeam) then
				relevantToTeam = isFromMain
					and Logic.nilIfEmpty(record.toteamtemplate)
					or record.extradata.toteamsectemplate
			end

			---@type TeamHistoryEntry
			local entry = {
				type = transferType,

				-- Person related information
				pagename = record.player,
				displayname = record.extradata.displayname,
				flag = record.nationality,

				-- Date and references
				date = record.date,
				dateDisplay = record.extradata.displaydate,
				references = record.reference,

				-- Roles
				fromRole = parseRelevantRole(Side.from, record, relevantFromTeam, isFromMain),
				toRole = parseRelevantRole(Side.to, record, relevantToTeam, isToMain),

				fromTeam = relevantFromTeam,
				toTeam = relevantToTeam,

				-- Other
				wholeTeam = Logic.readBool(record.wholeteam),
				position = record.extradata.position,
				faction = record.extradata.faction
			}

			-- Skip this transfer if there is no relevant change, i.e. the role in this team didn't change
			-- E.g. this is grabbed by secondary team, but only main team changed
			if relevantFromTeam == relevantToTeam
					and entry.fromRole == entry.toRole then
				return
			end

			table.insert(self.playersTeamHistory[record.player], entry)
		end
	)
	pageVars:set(teamHistoryKey, Json.stringify(self.playersTeamHistory))
end

---Builds the conditions to fetch all transfers related
---to the given team, respecting historical templates.
---@return string
function SquadAuto:buildConditions()
	local conditions = Condition.Tree(BooleanOperator.any)
	Array.forEach(self.config.teams, function (templatename)
		conditions:add{
			Condition.Node(Condition.ColumnName('fromteamtemplate'), Comparator.eq, templatename),
			Condition.Node(Condition.ColumnName('extradata_fromteamsectemplate'), Comparator.eq, templatename),
			Condition.Node(Condition.ColumnName('toteamtemplate'), Comparator.eq, templatename),
			Condition.Node(Condition.ColumnName('extradata_toteamsectemplate'), Comparator.eq, templatename)
		}
	end)

	return conditions:toString()
end

---@return SquadPersonArgs[]
function SquadAuto:selectEntries()
	return Array.filter(
		Array.extend(
			Array.flatMap(
				Array.extractValues(self.playersTeamHistory),
				FnUtil.curry(self._selectHistoryEntries, self)
			),
			self.manualPlayers
		),
		--- Selects the appropriate entries based on the role.
		---@param entry SquadPersonArgs
		function(entry)
			if self.config.status == SquadUtils.SquadStatus.INACTIVE then
				-- For SquadStatus.INACTIVE the entries are already preselected
				-- and won't have the role set to Inactive.
				-- This also matches manual Squad, where status is inactive and role can e.g. be "On Loan"

				return true
			end

			local roles = RoleUtil.readRoleArgs(table.concat({entry.role, entry.position}, ','))
			local hasStaffRoles = Array.any(roles, function(role)
				return role.type == RoleUtil.ROLE_TYPE.STAFF
					or role.type == RoleUtil.ROLE_TYPE.UNKNOWN -- Unknown roles are assumed to be non-player
			end)

			if self.config.type == SquadUtils.SquadType.STAFF then
				return hasStaffRoles
			end

			return not hasStaffRoles
		end
	)
end

---Returns a function that maps a set of transfers to a list of SquadAutoPersons.
---Behavior depends on the current config:
---If the status is (in)active, then at most one entry will be returned
---If the status is former(_inactive), there might be multiple entries returned
---If the type does not match, no entries are returned
---@private
---@param entries TeamHistoryEntry[]
---@return SquadPersonArgs[]
function SquadAuto:_selectHistoryEntries(entries)
	-- Select entries to match status
	if self.config.status == SquadUtils.SquadStatus.ACTIVE then
		-- Only most recent transfer is relevant
		local last = entries[#entries]
		if (last.type == SquadAuto.TransferType.CHANGE or last.type == SquadAuto.TransferType.JOIN)
				and last.toRole ~= ROLE_INACTIVE then
			-- When the last transfer is a leave transfer, or the role is inactive, the person wouldn't be active
			return {self:_mapToSquadPerson(last)}
		end
	end

	if self.config.status == SquadUtils.SquadStatus.INACTIVE then
		local last, secondToLast = entries[#entries], entries[#entries - 1]
		if secondToLast and last.type == SquadAuto.TransferType.CHANGE and last.toRole == ROLE_INACTIVE then
			return {self:_mapToSquadPerson(secondToLast, last)}
		end
	end

	if self.config.status == SquadUtils.SquadStatus.FORMER
		or self.config.status == SquadUtils.SquadStatus.FORMER_INACTIVE then
		local history = {}

		local joinEntry, inactiveEntry

		Array.forEach(entries, function (entry)
			if entry.type == SquadAuto.TransferType.JOIN then
				if joinEntry then
					mw.log('Invalid transfer history for player ' .. entry.pagename)
					mw.logObject(entry, 'Invalid entry: Duplicate JOIN. Skipping')
					mw.ext.TeamLiquidIntegration.add_category('SquadAuto with invalid player history')
					return
				end
				joinEntry = entry
				return
			end
			if not joinEntry then
				mw.log('Invalid transfer history for player ' .. entry.pagename)
				mw.logObject(entry, 'Invalid entry: Missing previous JOIN. Skipping')
				mw.ext.TeamLiquidIntegration.add_category('SquadAuto with invalid player history')
				return
			end

			if entry.type == SquadAuto.TransferType.CHANGE and entry.toRole == ROLE_INACTIVE then
				-- FORMER_INACTIVE enables the Inactive Date display
				self.config.status = SquadUtils.SquadStatus.FORMER_INACTIVE
				inactiveEntry = entry
				return
			end

			table.insert(history, self:_mapToSquadPerson(joinEntry, inactiveEntry, entry))
			joinEntry = nil
			inactiveEntry = nil

			if entry.type == SquadAuto.TransferType.CHANGE then
				joinEntry = entry
			end
		end)

		return history
	end

	return {}
end

---Maps one or a pair of TeamHistoryEntries to a single SquadAutoPerson
---@private
---@param joinEntry TeamHistoryEntry
---@param inactiveEntry TeamHistoryEntry | nil
---@param leaveEntry TeamHistoryEntry | nil
---@return SquadPersonArgs
function SquadAuto:_mapToSquadPerson(joinEntry, inactiveEntry, leaveEntry)
	inactiveEntry = inactiveEntry or {}
	leaveEntry = leaveEntry or {}

	local joinReference = TransferRefs.useReferences(joinEntry.references, joinEntry.date)
	local inactiveReference = TransferRefs.useReferences(inactiveEntry.references, inactiveEntry.date)
	local leaveReference = TransferRefs.useReferences(leaveEntry.references, leaveEntry.date)


	local function attachReference(entry, reference)
		return (entry.dateDisplay or entry.date or '') .. ' ' .. reference
	end

	local joindate = attachReference(joinEntry, joinReference)
	local inactivedate = attachReference(inactiveEntry, inactiveReference)
	local leavedate = attachReference(leaveEntry, leaveReference)

	---@type SquadPersonArgs
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
		race = leaveEntry.faction or joinEntry.faction
		-- game,
	}

	-- On leave: Fetch the next team a person joined
	if Logic.isNotEmpty(leaveEntry) and Logic.isEmpty(entry.newteam) then
		local newTeam, newRole, newDate = SquadAuto._fetchNextTeam(joinEntry.pagename, leaveEntry.date)
		if newTeam then
			entry.newteam = newTeam
			entry.newteamrole = newRole
			entry.newteamdate = newDate
		end
	end

	return entry
end

---Fetches the next team a person joined after a given date
---@private
---@param pagename string
---@param date string
---@return string? newTeam
---@return string? newRole
---@return string? newDate
function SquadAuto._fetchNextTeam(pagename, date)
	local conditions = Condition.Tree(BooleanOperator.all)
		:add{
			Condition.Util.anyOf(Condition.ColumnName('player'), {pagename, string.gsub(pagename, ' ', '_')}),
			Condition.Node(Condition.ColumnName('date'), Comparator.ge, date),
			Condition.Node(Condition.ColumnName('toteamtemplate'), Comparator.neq, ''),
		}

	local transfer = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = conditions:toString(),
		limit = 1,
		order = 'date asc, objectname desc',
		query = 'toteamtemplate, role2, date'
	})[1] or {}

	return transfer.toteamtemplate, transfer.role2, transfer.date
end

---Sorts a list of SquadPersonArgs
-- Active entries (no leavedate) sorted by joindate,
-- Former entries sorted by leavedate
---@private
---@param entries SquadPersonArgs[]
---@param useRankSort boolean?
---@return SquadPersonArgs[]
function SquadAuto._sortEntries(entries, useRankSort)
	return Array.sortBy(entries, function (element)
		return {
			useRankSort and SquadAutoRank[element.position] or SquadAutoRank[DEFAULT_RANK_KEY],
			useRankSort and SquadAutoRank[element.role] or SquadAutoRank[DEFAULT_RANK_KEY],
			element.leavedate or element.joindate or '',
			element.id
		}
	end)
end

return SquadAuto
