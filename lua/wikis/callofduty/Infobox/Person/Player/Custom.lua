---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local GameAppearances = require('Module:Infobox/Extension/GameAppearances')
local Lua = require('Module:Lua')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.autoTeam = true
	player.args.history = TeamHistoryAuto.results{
		convertrole = true,
		addlpdbdata = true,
		player = player.pagename
	}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'custom' then
		return {
			Cell{name = 'Game Appearances', content = GameAppearances.player{player = self.caller.pagename}},
		}
	end
	return widgets
end

return CustomPlayer
