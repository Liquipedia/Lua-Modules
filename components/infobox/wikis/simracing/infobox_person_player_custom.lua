---
-- @Liquipedia
-- wiki=simracing
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local GameAppearances = require('Module:GetGameAppearances')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class SimracingInfoboxPlayer: Person
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
	if id == 'custom' then
		return {
			Cell{name = 'Game Appearances', content = GameAppearances.player{player = self.caller.pagename}},
		}
	end

	return widgets
end

return CustomPlayer
