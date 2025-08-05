---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Character = Lua.import('Module:Infobox/Character')

---@class CustomCharacterInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	return CustomCharacter(frame):createInfobox()
end

return CustomCharacter
