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

local Widgets = Lua.import('Module:Widget/All')
local Builder = Widgets.Builder
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class DeltaforceAgentInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
---@class DeltaforceAgentInfoboxWidgetInjector: WidgetInjector
---@field caller DeltaforceAgentInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Agents'
	return character:createInfobox()
end

---@param id string
---@param widgets Renderable[]
---@return Renderable[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(
			widgets,
			Title{children = 'Abilities'},
			Builder{
				builder = function()
					local gadgets = self.caller:getAllArgsForBase(args, 'gadget')
					return {
						Cell{
							name = 'Gadgets',
							children = gadgets,
						}
					}
				end
			},
			Cell{name = 'Tactical Gear', children = {args.tacticalgear}},
			Cell{name = 'Trait', children = {args.trait}}
		)
	end

	return widgets
end

return CustomCharacter
