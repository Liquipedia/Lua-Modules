---
-- @Liquipedia
-- page=Module:Roles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Table = Lua.import('Module:Table')

local ContractRoles = Lua.import('Module:ContractRoles', {loadData = true})
local StaffRoles = Lua.import('Module:StaffRoles', {loadData = true})
local PlayerTeamRoles = Lua.import('Module:PlayerTeamRoles', {loadData = true})
local InGameRoles = Lua.requireIfExists('Module:InGameRoles', {loadData = true})

local Roles = {
	ContractRoles = ContractRoles,
	StaffRoles = StaffRoles,
	InGameRoles = InGameRoles,
	PlayerTeamRoles = PlayerTeamRoles,
	All = Table.merge(ContractRoles, StaffRoles, InGameRoles, PlayerTeamRoles)
}

return Roles
