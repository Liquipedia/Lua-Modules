local SquadTypes = {}

---@enum SquadStatus
SquadTypes.SquadStatus = {
	ACTIVE = 0,
	INACTIVE = 1,
	FORMER = 2,
	FORMER_INACTIVE = 3, -- TODO: Investigate if this is still needed, I think FORMER handles this now
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