---
-- @Liquipedia
-- wiki=commons
-- page=Module:Roles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local ContractRoles = Lua.import('Module:ContractRoles')
local StaffRoles = Lua.import('Module:StaffRoles')
local InGameRoles = Lua.requireIfExists('Module:InGameRoles', {loadData = true})

local Roles = {
	ContractRoles = ContractRoles,
	StaffRoles = StaffRoles,
	InGameRoles = InGameRoles,
	All = Table.merge(ContractRoles, StaffRoles, InGameRoles)
}

return Roles
