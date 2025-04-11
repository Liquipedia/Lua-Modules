---
-- @Liquipedia
-- wiki=tft
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Staff and Talents
	analyst = {category = 'Analyst', value = 'Analyst', type = 'talent'},
	observer = {category = 'Observer', value = 'Observer', type = 'talent'},
	host = {category = 'Host', value = 'Host', type = 'talent'},
	journalist = {category = 'Journalist', value = 'Journalist', type = 'talent'},
	expert = {category = 'Expert', value = 'Expert', type = 'talent'},
	coach = {category = 'Coach', value = 'Coach', type = 'staff'},
	caster = {category = 'Caster', value = 'Caster', type = 'talent'},
	talent = {category = 'Talent', value = 'Talent', type = 'talent'},
	manager = {category = 'Manager', value = 'Manager', type = 'staff'},
	producer = {category = 'Producer', value = 'Producer', type = 'talent'},
	organizer = {category = 'Tournament Organizer', value = 'Tournament Organizer', type = 'staff'},
	creator = {category = 'Content Creator', value = 'Content Creator', type = 'talent'},
}
ROLES['assistant coach'] = ROLES.coach

local DEFAULT_TYPE = 'player'

---@class TftInfoboxPlayer: Person
---@field role {category: string?, value: string?, type: string?}
---@field role2 {category: string?, value: string?, type: string?}
---@field role3 {category: string?, value: string?, type: string?}
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.role = player:_getRoleData(player.args.role)
	player.role2 = player:_getRoleData(player.args.role2)
	player.role3 = player:_getRoleData(player.args.role3)

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'role' then
		return {
			Cell{name = 'Role', content = {
				caller.role.value,
				caller.role2.value,
				caller.role3.value,
			}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.role = self.role.value
	lpdbData.extradata.role2 = self.role2.value
	lpdbData.extradata.role3 = self.role3.value

	return lpdbData
end

---@param role string
---@return {category: string?, value: string?, type: string?}
function CustomPlayer:_getRoleData(role)
	return ROLES[(role or ''):lower()] or {}
end

---@param args table
function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('role', self.role.value)
	Variables.varDefine('role2', self.role2.value)
	Variables.varDefine('role3', self.role3.value)
end

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	return {
		store = self.role.type or DEFAULT_TYPE,
		category = self.role.category or mw.getContentLanguage():ucfirst(DEFAULT_TYPE)
	}
end

return CustomPlayer
