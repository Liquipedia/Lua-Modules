---
-- @Liquipedia
-- wiki=omegastrikers
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomCharacter = Class.new()
local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = Character(frame)
	_args = character.args
	character.createWidgetInjector = CustomCharacter.createWidgetInjector
	return character:createInfobox()
end

---@return WidgetInjector
function CustomCharacter:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Age',
		content = {_args.age}
	})

	table.insert(widgets, Cell{
		name = 'Cost',
		content = {'[[File:Omega Strikers Striker Credits.png|20px]] ' .. _args.strikercredits ..
				'  [[File:Omega Strikers Ody Points.png|20px]] ' .. _args.odypoints}
	})

	table.insert(widgets, Cell{
		name = 'Affiliation',
		content = {'[[File:' .. _args.affiliation .. ' allmode.png|20px]] ' .. _args.affiliation}
	})

	table.insert(widgets, Cell{
		name = 'Voice Actor(s)',
		content = {_args.voiceactors}
	})

	table.insert(widgets, Title{name = 'Abilities'})

	table.insert(widgets, Cell{
		name = 'Primary',
		content = {'[[File:' .. _args.name .. ' - Primary.png|20px]] ' .. _args.primary}
	})

	table.insert(widgets, Cell{
		name = 'Secondary',
		content = {'[[File:' .. _args.name .. ' - Secondary.png|20px]] ' .. _args.secondary}
	})

	table.insert(widgets, Cell{
		name = 'Special',
		content = {'[[File:' .. _args.name .. ' - Special.png|20px]] ' .. _args.special}
	})

	return widgets
end

return CustomCharacter
