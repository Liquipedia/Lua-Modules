---
-- @Liquipedia
-- page=Module:Features/Squad/Types
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@alias SquadWrapper {players: table[], squadType: SquadType, squadStatus: SquadStatus, title: string?, args: table}

---@class SquadPersonArgs
---@field name string? Real name
---@field id string? Display name
---@field link string? Page name
---@field flag string?
---@field position string?
---@field role string?
---@field captain string? Truthy, only when role is empty
---@field igl string? Truthy, alternative to captain
---@field newteam string? as team template
---@field newteamrole string?
---@field newrole string? -- Alternative to newteamrole
---@field joindate string? including reference
---@field leavedate string? including reference
---@field inactivedate string? including reference
---@field status SquadStatus?
---@field type SquadType?
---@field team string? as loanedto
---@field teamrole string? as loanedtorole
---@field newteamdate string?
---@field faction string?
---@field race string?
---@field activeteam string?
---@field activeteamrole string?
---@field game game?
---@field joindateref table<string, string>?
---@field leavedateref table<string, string>?
---@field inactivedateref table<string, string>?

--- One transfer, seen from the point of view of one team.
---@class (exact) TeamHistoryEntry
---@field pagename string
---@field displayname string
---@field flag string
---@field date string
---@field dateDisplay string?
---@field type TransferType
---@field references table<string, string>
---@field wholeTeam boolean
---@field position string?
---@field fromTeam string?
---@field fromRole string?
---@field toTeam string?
---@field toRole string?
---@field faction string?

--- The transfers behind a single squad row: what put a person on the team, what took them off the
--- active squad, and what ended their time there. A person can have several of these on one team,
--- and `inactiveEntry` is the transfer that made them inactive, not the last one before leaving.
---@class (exact) SquadStint
---@field joinEntry TeamHistoryEntry
---@field inactiveEntry TeamHistoryEntry?
---@field leaveEntry TeamHistoryEntry?

--- A transfer that could not be fitted into the history. The caller decides how to report it.
---@class SquadHistoryWarning
---@field reason string
---@field entry TeamHistoryEntry

---@class SquadHistorySelection
---@field stints SquadStint[]
---@field warnings SquadHistoryWarning[]
---@field hasFormerInactiveEntry boolean whether a transfer took someone off the active squad

local SquadTypes = {}

---@enum TransferType
SquadTypes.TransferType = {
	LEAVE = 'LEAVE',
	JOIN = 'JOIN',
	CHANGE = 'CHANGE',
}

---@enum TransferSide
SquadTypes.TransferSide = {
	FROM = 'from',
	TO = 'to',
}

--- The role a transfer sets to take someone off the active squad.
SquadTypes.ROLE_INACTIVE = 'Inactive'

---@enum SquadStatus
SquadTypes.SquadStatus = {
	ACTIVE = 0,
	INACTIVE = 1,
	FORMER = 2,
	FORMER_INACTIVE = 3,
}

---@type {string: SquadStatus}
SquadTypes.StatusToSquadStatus = {
	active = SquadTypes.SquadStatus.ACTIVE,
	inactive = SquadTypes.SquadStatus.INACTIVE,
	former = SquadTypes.SquadStatus.FORMER,
}

---@type {SquadStatus: string}
SquadTypes.SquadStatusToStorageValue = {
	[SquadTypes.SquadStatus.ACTIVE] = 'active',
	[SquadTypes.SquadStatus.INACTIVE] = 'inactive',
	[SquadTypes.SquadStatus.FORMER] = 'former',
	[SquadTypes.SquadStatus.FORMER_INACTIVE] = 'former',
}

---@enum SquadType
SquadTypes.SquadType = {
	PLAYER = 0,
	STAFF = 1,
}

---@type table<string, SquadType>
SquadTypes.TypeToSquadType = {
	player = SquadTypes.SquadType.PLAYER,
	staff = SquadTypes.SquadType.STAFF,
}

---@type {SquadType: string}
SquadTypes.SquadTypeToStorageValue = {
	[SquadTypes.SquadType.PLAYER] = 'player',
	[SquadTypes.SquadType.STAFF] = 'staff',
}

SquadTypes.specialTeamsTemplateMapping = {
	retired = 'Team/retired',
	inactive = 'Team/inactive',
	['passed away'] = 'Team/passed away',
	military = 'Team/military',
}

return SquadTypes
