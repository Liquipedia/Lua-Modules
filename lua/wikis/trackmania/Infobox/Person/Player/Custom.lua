---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class TrackmaniaInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))
	player.args.achievements = Achievements.player{noTemplate = true}
	player.args['trackmania-io'] = player.args.trackmania_id

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'status' then
		table.insert(widgets, Cell{name = 'Years Active (Player)', content = {self.caller.args.years_active}})
	end

	return widgets
end

return CustomPlayer
