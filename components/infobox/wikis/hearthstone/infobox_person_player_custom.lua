---
-- @Liquipedia
-- wiki=hearthstone
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Talents
	['host'] = {category = 'Host', variable = 'Host', talent = true},
	['caster'] = {category = 'Casters', variable = 'Caster', talent = true},
}

---@class HearthstoneInfoboxPlayer: Person
---@field role {category: string, variable: string, talent: boolean?}?
---@field role2 {category: string, variable: string, talent: boolean?}?
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

local GM_ICON = '[[File:HS grandmastersIconSmall.png|x15px|link=Grandmasters]]&nbsp;'

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

	if id == 'custom' then
		local grandMaster = args.grandmasters and (GM_ICON .. args.grandmasters) or nil
		table.insert(widgets, Cell{name = 'Grandmasters', content = {grandMaster}})

	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				caller:_displayRole(caller.role),
				caller:_displayRole(caller.role2),
			}},
		}
	end

	return widgets
end

---@param role string?
---@return {category: string, variable: string, talent: boolean?}?
function CustomPlayer:_getRoleData(role)
	return ROLES[(role or ''):lower()]
end

---@param roleData {category: string, variable: string, talent: boolean?}?
---@return string?
function CustomPlayer:_displayRole(roleData)
	if not roleData then return end

	return Page.makeInternalLink(roleData.variable, ':Category:' .. roleData.category)
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

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	if self.role.talent then
		return {store = 'talent', category = 'Talent'}
	end
	return {store = 'player', category = 'Player'}
end

return CustomPlayer
