---
-- @Liquipedia
-- wiki=arenafps
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local ROLES = {
	-- Players
	duel = {variable = 'Duel', isplayer = true},
	tdm = {variable = 'TDM', isplayer = true},
	ctf = {variable = 'CTF', isplayer = true},
	sacrifice = {variable = 'Sacrifice', isplayer = true},
	['3vs3'] = {variable = '3vs3', isplayer = true},

	-- Staff and Talents
	analyst = {variable = 'Analyst', isplayer = false},
	manager = {variable = 'Manager', isplayer = false},
	caster = {variable = 'Caster', isplayer = false},
}
ROLES.dueler = ROLES.duel

---@class ArenafpsInfoboxPlayer: Person
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

	if id == 'custom' then
		local games = Array.map(Array.extractKeys(Table.filterByKey(args, Game.isValid)), function(game)
			return Page.makeInternalLink({}, Game.name{game = game}, Game.link{game = game})
		end)
		table.insert(widgets, Cell{name = 'Games', content = games})
	elseif id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = Array.map(self.caller:getAllArgsForBase(args, 'role'), function(role)
				return CustomPlayer._roleDisplay(role)
			end)},
		}
	elseif id == 'status' then
		table.insert(widgets, Cell{name = 'Years Active (Player)', content = {args.years_active}})
		table.insert(widgets, Cell{name = 'Years Active (Org)', content = {args.years_active_manage}})
	end
	return widgets
end

---@param role string?
---@return string?
function CustomPlayer._roleDisplay(role)
	local roleData = ROLES[(role or ''):lower()]
	return roleData and roleData.variable or nil
end

return CustomPlayer
