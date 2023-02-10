---
-- @Liquipedia
-- wiki=fifa
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args

	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{name = 'Agency', content = {Page.makeInternalLink(_args.agency)}})

	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

return CustomPlayer