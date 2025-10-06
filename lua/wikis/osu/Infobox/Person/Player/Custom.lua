---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Widgets = Lua.import('Module:Widget/All')

local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

local Cell = Widgets.Cell

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	return player:createInfobox()
end

---@return Widget
function CustomPlayer:createBottomContent()
	return UpcomingTournaments.player{name = self.pagename}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'status' then
		table.insert(widgets, Cell{name = 'Years Active', children = {args.years_active}})
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			children = {args.retired}
		})
	end
	return widgets
end

return CustomPlayer
