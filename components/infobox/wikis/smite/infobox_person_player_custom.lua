---
-- @Liquipedia
-- wiki=smite
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Region = require('Module:Region')
local Role = require('Module:Role')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class SmiteInfoboxPlayer: Person
---@field role table
---@field role2 table
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)

	player:setWidgetInjector(CustomInjector(player))

	player.args.autoTeam = true
	player.args.history = TeamHistoryAuto._results{
		convertrole = true,
		iconModule = 'Module:PositionIcon/data',
		player = player.pagename
	}
	player.role = Role.run{role = player.args.role}
	player.role2 = Role.run{role = player.args.role2}

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'region' then return {}
	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = {self.caller.role.display, self.caller.role2.display}}
		}
	end
	return widgets
end

return CustomPlayer
