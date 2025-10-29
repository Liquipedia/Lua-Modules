---
-- @Liquipedia
-- page=Module:Infobox/Role/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Role = Lua.import('Module:Infobox/Role')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class IlluviumRoleInfobox: RoleInfobox
local CustomRole = Class.new(Role)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomRole.run(frame)
	local role = CustomRole(frame)
	role:setWidgetInjector(CustomInjector(role))

	return role:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Synergy Levels', children = { args.synergylevels }}
		)
		return widgets
	end

        return widgets
end

return CustomRole
