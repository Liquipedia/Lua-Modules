---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = Lua.import('Module:Widget/All')

---@class DeltaforceCharacterInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
---@class DeltaforceCharacterInfoboxWidgetInjector: WidgetInjector
---@field caller DeltaforceCharacterInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Characters'
	return character:createInfobox()
end

---@param lpdbData table
---@param args table
---@return table
function CustomCharacter:addToLpdb(lpdbData, args)
	lpdbData.extradata.class = args.class
	return lpdbData
end

return CustomCharacter
