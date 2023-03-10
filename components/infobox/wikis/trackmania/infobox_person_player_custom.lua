---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

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

	_args['trackmania-io'] = _args.trackmania_id

	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		table.insert(widgets, Cell{name = 'Years Active (Player)', content = {_args.years_active}})
	end

	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

return CustomPlayer
