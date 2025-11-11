---
-- @Liquipedia
-- page=Module:Role/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local String = Lua.import('Module:StringUtils')

local Roles = Lua.import('Module:Roles')

--- TODO: In the future this should be moved to role data entry
local POSITION_ICON_DATA = Lua.requireIfExists('Module:PositionIcon/data', {loadData = true})

local RoleUtil = {}

---@class RoleBaseData
---@field display string
---@field category string

---@class RoleData
---@field category string
---@field display string
---@field key string?
---@field type 'contract'|'staff'|'ingame'|'unknown'
---@field icon string?

function RoleUtil.readRoleArgs(input)
	return Array.map(Array.parseCommaSeparatedString(input), RoleUtil._createRoleData)
end

function RoleUtil._createRoleData(roleKey)
	if String.isEmpty(roleKey) then return nil end

	local key = roleKey:lower()
	local roleData = Roles.All[key]

	--- Backwards compatibility for old roles
	if not roleData then
		mw.ext.TeamLiquidIntegration.add_category('Pages with invalid role input')
		local display = String.upperCaseFirst(roleKey)
		roleData = {
			display = display,
			category = display .. 's',
			key = display,
		}
	end

	local roleType = function()
		if Roles.ContractRoles[key] then
			return 'contract'
		elseif Roles.StaffRoles[key] then
			return 'staff'
		elseif Roles.InGameRoles[key] then
			return 'ingame'
		else
			return 'unknown'
		end
	end

	return {
		display = roleData.display,
		category = roleData.category,
		key = key,
		type = roleType(),
		icon = POSITION_ICON_DATA and POSITION_ICON_DATA[key] or nil,
	}
end

return RoleUtil
