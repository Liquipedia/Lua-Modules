---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Character = Lua.import('Module:Infobox/Character')

local CustomCharacter = {}

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	return Character(frame):createInfobox()
end

return CustomCharacter
