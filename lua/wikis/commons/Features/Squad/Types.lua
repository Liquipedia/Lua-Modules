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

local SquadTypes = {}

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

---@type {string: SquadType}
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
