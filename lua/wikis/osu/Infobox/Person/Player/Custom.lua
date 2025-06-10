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

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.history = TeamHistoryAuto.results{convertrole = true}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'status' then
		table.insert(widgets, Cell{name = 'Years Active', content = {args.years_active}})
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			content = {args.retired}
		})
	end
	return widgets
end

return CustomPlayer
