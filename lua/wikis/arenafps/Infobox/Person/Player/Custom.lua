---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

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
		table.insert(widgets, Cell{name = 'Games', children = games})
	elseif id == 'region' then return {}
	elseif id == 'status' then
		table.insert(widgets, Cell{name = 'Years Active (Player)', children = {args.years_active}})
		table.insert(widgets, Cell{name = 'Years Active (Org)', children = {args.years_active_manage}})
	end
	return widgets
end

return CustomPlayer
