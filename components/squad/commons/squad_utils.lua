---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Utils
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Table = require('Module:Table')

local SquadAutoRefs = Lua.import('Module:SquadAuto/References')

local SquadUtils = {}

---@enum SquadType
SquadUtils.SquadType = {
	ACTIVE = 0,
	INACTIVE = 1,
	FORMER = 2,
	FORMER_INACTIVE = 3,
}

---@type {string: SquadType}
SquadUtils.StatusToSquadType = {
	active = SquadUtils.SquadType.ACTIVE,
	inactive = SquadUtils.SquadType.INACTIVE,
	former = SquadUtils.SquadType.FORMER,
}

---@type {SquadType: string}
SquadUtils.SquadTypeToStorageValue = {
	[SquadUtils.SquadType.ACTIVE] = 'active',
	[SquadUtils.SquadType.INACTIVE] = 'inactive',
	[SquadUtils.SquadType.FORMER] = 'former',
	[SquadUtils.SquadType.FORMER_INACTIVE] = 'former',
}

-- TODO: Decided on all valid types
SquadUtils.validPersonTypes = {'player', 'staff'}
SquadUtils.defaultPersonType = 'player'

---@param status string?
---@return SquadType?
function SquadUtils.statusToSquadType(status)
	if not status then
		return
	end
	return SquadUtils.StatusToSquadType[status:lower()]
end

---@param args table
---@return table[]
function SquadUtils.parsePlayers(args)
	return Array.mapIndexes(function(index)
		return Json.parseIfString(args[index])
	end)
end

---@param players {inactivedate: string|nil}[]
---@return boolean
function SquadUtils.anyInactive(players)
	return Array.any(players, function(player)
		return Logic.isNotEmpty(player.inactivedate)
	end)
end

---@param player table
---@return table
function SquadUtils.convertAutoParameters(player)
	local newPlayer = Table.copy(player)
	local joinReference = SquadAutoRefs.useReferences(player.joindateRef, player.joindate)
	local leaveReference = SquadAutoRefs.useReferences(player.leavedateRef, player.leavedate)

	-- Map between formats
	newPlayer.joindate = (player.joindatedisplay or player.joindate) .. ' ' .. joinReference
	newPlayer.leavedate = (player.leavedatedisplay or player.leavedate) .. ' ' .. leaveReference
	newPlayer.inactivedate = player.leavedate

	newPlayer.link = player.page
	newPlayer.role = player.thisTeam.role
	newPlayer.position = player.thisTeam.position
	newPlayer.team = player.thisTeam.role == 'Loan' and player.oldTeam.team

	newPlayer.newteam = player.newTeam.team
	newPlayer.newteamrole = player.newTeam.role
	newPlayer.newteamdate = player.newTeam.date

	return newPlayer
end

return SquadUtils
