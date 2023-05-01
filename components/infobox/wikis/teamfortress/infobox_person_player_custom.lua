---
-- @Liquipedia
-- wiki=teamfortress
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Template = require('Module:Template')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local CustomPlayer = Class.new()
local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args

	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'role' then
		if _args.role then
			return {
				Cell{name = 'Main', content = {Template.safeExpand(mw.getCurrentFrame(), 'Class/'.. _args.role)}}
			}
		end
	end
	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

return CustomPlayer
