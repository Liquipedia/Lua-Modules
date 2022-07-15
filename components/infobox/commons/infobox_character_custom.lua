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
	return Character(frame):createInfobox(frame)
end

return CustomCharacter
