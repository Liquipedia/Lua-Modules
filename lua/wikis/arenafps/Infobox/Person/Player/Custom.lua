---
-- @Liquipedia
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
	elseif id == 'status' then
		table.insert(widgets, Cell{name = 'Years Active (Player)', content = {args.years_active}})
		table.insert(widgets, Cell{name = 'Years Active (Org)', content = {args.years_active_manage}})
	end
	return widgets
end

return CustomPlayer
