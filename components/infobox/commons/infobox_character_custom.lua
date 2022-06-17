---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Character = require('Module:Infobox/Character')

local CustomCharacter = {}

function CustomCharacter.run(frame)
	local character = Character(frame)
	return character:createInfobox(frame)
end

return CustomCharacter
