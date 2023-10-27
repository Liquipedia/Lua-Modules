
---
-- @Liquipedia
-- wiki=esports
-- page=Module:Infobox/Game/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Game = Lua.import('Module:Infobox/Game', {requireDevIfEnabled = true})

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomGame = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _game

function CustomGame.run(frame)
	local game = Game(frame)
	_game = game
	
	game.createWidgetInjector = CustomGame.createWidgetInjector
	game.addToLpdb = CustomGame.addToLpdb
	
	_args = game.args
	return game:createInfobox()
end

---@return WidgetInjector
function CustomGame:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Engine',
		content = {_args.engine}
	})
	table.insert(widgets, Cell{
		name = 'Genre(s)',
		content = {_args.genre}
	})
	table.insert(widgets, Cell{
		name = 'Mode(s)',
		content = {_args.mode}
	})
	
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomGame:addToLpdb(lpdbData, args)
	lpdbData.extradata.engine = _args.engine
	lpdbData.extradata.genre = _args.genre
	lpdbData.extradata.mode = _args.mode
	
	return lpdbData
end

return CustomGame
