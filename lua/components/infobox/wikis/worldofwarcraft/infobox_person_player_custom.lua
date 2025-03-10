---
-- @Liquipedia
-- wiki=worldofwarcraft
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Playes
	healer = {category = 'Healers', variable = 'Healer'},
	dps = {category = 'DPS players', variable = 'DPS'},

	-- Staff and Talents
	analyst = {category = 'Analysts', variable = 'Analyst'},
	host = {category = 'Hosts', variable = 'Host'},
	caster = {category = 'Casters', variable = 'Caster'},
}

---@class WorldofwarcraftInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				CustomPlayer._roleDisplay(args.role),
				CustomPlayer._roleDisplay(args.role2)
			}},
		}
	end
	return widgets
end

---@param role string?
---@return {category: string, variable: string}?
function CustomPlayer._getRoleData(role)
	return ROLES[(role or ''):lower()]
end

---@param role string?
---@return string?
function CustomPlayer._roleDisplay(role)
	local roleData = CustomPlayer._getRoleData(role)
	if not roleData then
		return
	end
	return '[[:Category:' .. roleData.category .. '|' .. roleData.variable .. ']]'
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	local roleData = CustomPlayer._getRoleData(self.args.role)
	local role2Data = CustomPlayer._getRoleData(self.args.role2)

	if roleData then
		table.insert(categories, roleData.category)
	end

	if role2Data then
		table.insert(categories, role2Data.category)
	end

	return categories
end

return CustomPlayer
