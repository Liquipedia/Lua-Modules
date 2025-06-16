---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class FreefireCharacterInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
---@class FreefireCharacterInfoboxWidgetInjector: WidgetInjector
---@field caller FreefireCharacterInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	return character:createInfobox()
end
---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Date of Birth', content = {args.birthdate}},
			Cell{name = 'Age', content = {args.age}},
			Cell{name = 'Gender', content = {args.gender}},
			Cell{name = 'Occupation', content = {args.occupation}},
			Cell{name = 'Unlocked by', content = {args.unlock}},
			Title{children = 'Special Survival Ability'},
			Cell{name = 'Legend Type', content = {args.ability}}
		)
	end

	return widgets
end

return CustomCharacter
