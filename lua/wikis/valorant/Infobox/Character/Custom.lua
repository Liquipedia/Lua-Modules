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

local Widgets = Lua.import('Module:Widget/All')
local Builder = Widgets.Builder
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class ValorantHeroInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Agents'
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(
			widgets,
			Title{children = 'Abilities'},
			Builder{
				builder = function()
					local abilities = self.caller:getAllArgsForBase(args, 'ability')
					return {
						Cell{
							name = 'Abilities',
							content = abilities,
						}
					}
				end
			},
			Cell{name = 'Signature Ability', content = {args.signature}},
			Cell{name = 'Ultimate', content = {args.ultimate}}
		)
	end

	return widgets
end

return CustomCharacter
