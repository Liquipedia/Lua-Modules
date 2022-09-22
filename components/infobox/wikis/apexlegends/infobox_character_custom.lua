---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Character = Lua.import('Module:Infobox/Character', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomCharacter = Class.new()
local CustomInjector = Class.new(Injector)

local _args

function CustomCharacter.run(frame)
	local character = Character(frame)
	_args = character.args
	character.addToLpdb = CustomCharacter.addToLpdb
	character.createWidgetInjector = CustomCharacter.createWidgetInjector
	return character:createInfobox(frame)
end

function CustomCharacter:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Age',
		content = {_args.age}
	})

	table.insert(widgets, Cell{
		name = 'Home World',
		content = {_args.homeworld}
	})

	table.insert(widgets, Title{name = 'Abilities'})

	table.insert(widgets, Cell{
		name = 'Legend Type',
		content = {_args.legendtype}
	})

	table.insert(widgets, Cell{
		name = 'Passive',
		content = {'[[File:' .. _args.name .. ' - Passive.png|20px]] ' .. _args.passive}
	})

	table.insert(widgets, Cell{
		name = 'Tactical',
		content = {'[[File:' .. _args.name .. ' - Active.png|20px]] ' .. _args.active}
	})

	table.insert(widgets, Cell{
		name = 'Ultimate',
		content = {'[[File:' .. _args.name .. ' - Ultimate.png|20px]] ' .. _args.ultimate}
	})

	return widgets
end

function CustomCharacter:addToLpdb(lpdbData)
	lpdbData.extradata.class = _args.legendtype
	return lpdbData
end

return CustomCharacter
