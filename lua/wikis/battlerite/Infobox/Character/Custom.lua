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

local Widgets = Lua.import('Module:Widget/Infobox/All')
local Cell = Widgets.Cell

---@class BattleriteCharacterInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
---@class BattleriteCharacterInfoboxWidgetInjector: WidgetInjector
---@field caller BattleriteCharacterInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character.args.informationType = 'Champion'
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
			Cell{name = 'Health', content = {args.health}}
		)
	end

	return widgets
end

return CustomCharacter
