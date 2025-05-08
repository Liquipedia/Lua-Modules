---
-- @Liquipedia
-- wiki=worldoftanks
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	['igl'] = {category = 'In-game leaders', variable = 'In-game leader'},

	-- Staff and Talents
	['analyst'] = {category = 'Analysts', variable = 'Analyst', staff = true},
	['broadcast analyst'] = {category = 'Broadcast Analysts', variable = 'Broadcast Analyst', talent = true},
	['observer'] = {category = 'Observers', variable = 'Observer', talent = true},
	['host'] = {category = 'Host', variable = 'Host', talent = true},
	['coach'] = {category = 'Coaches', variable = 'Coach', staff = true},
	['caster'] = {category = 'Casters', variable = 'Caster', talent = true},
	['manager'] = {category = 'Managers', variable = 'Manager', staff = true},
	['streamer'] = {category = 'Streamers', variable = 'Streamer', talent = true},
}

---@class WorldoftanksInfoboxPlayer: Person
---@field role {category: string, variable: string, staff: boolean?, talent: boolean?}?
---@field role2 {category: string, variable: string, staff: boolean?, talent: boolean?}?
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.role = player:_getRoleData(player.args.role)
	player.role2 = player:_getRoleData(player.args.role2)

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'status' then
		return {
			Cell{name = 'Status', content = caller:_getStatusContents()},
			Cell{name = 'Years Active', content = {args.years_active}},
		}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				caller:_displayRole(caller.role),
				caller:_displayRole(caller.role2)
			}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end

	return widgets
end

---@return string[]
function CustomPlayer:_getStatusContents()
	return {Page.makeInternalLink({onlyIfExists = true}, self.args.status) or self.args.status}
end

---@param args table
function CustomPlayer:defineCustomPageVariables(args)
	Variables.varDefine('role', (self.role or {}).variable)
	Variables.varDefine('role2', (self.role2 or {}).variable)
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	return Array.append(categories,
		(self.role or {}).category,
		(self.role2 or {}).category
	)
end

---@param role string?
---@return {category: string, variable: string, staff: boolean?, talent: boolean?}?
function CustomPlayer:_getRoleData(role)
	return ROLES[(role or ''):lower()]
end

---@param roleData {category: string, variable: string, staff: boolean?, talent: boolean?}?
---@return string?
function CustomPlayer:_displayRole(roleData)
	if not roleData then return end

	if not self:shouldStoreData(self.args) then
		return roleData.variable
	end

	return Page.makeInternalLink(roleData.variable, ':Category:' .. roleData.category)
end

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	local roleData = self.role or {}
	if roleData.staff then
		return {store = 'staff', category = 'Staff'}
	elseif roleData.talent then
		return {store = 'talent', category = 'Talent'}
	end
	return {store = 'player', category = 'Player'}
end

return CustomPlayer
