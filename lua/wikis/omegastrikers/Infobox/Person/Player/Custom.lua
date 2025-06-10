---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

---@class OmegaStrikersInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)

	player:setWidgetInjector(CustomInjector(player))

	player.args.autoTeam = true
	player.args.history = TeamHistoryAuto.results{
		convertrole = true,
		player = player.pagename
	}

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	return widgets
end

return CustomPlayer
