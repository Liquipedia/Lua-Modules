---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = Lua.import('Module:Widget/Infobox/All')
local Cell = Widgets.Cell

---@class TF2CharacterInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
---@class TF2CharacterInfoboxWidgetInjector: WidgetInjector
---@field caller TF2CharacterInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character.args.informationType = 'Class'
	character:setWidgetInjector(CustomInjector(character))

	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'country' then
		return Cell{name = 'Origin', children = {args.origin}}
	elseif id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Voiced by', children = {args.voice}},
			Cell{name = 'Health', children = {args.hp}}
		)
	end

	return widgets
end

return CustomCharacter
