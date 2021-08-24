---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Patch = require('Module:Infobox/Patch')

local CustomPatch = {}

function CustomPatch.run(frame)
	local patch = Patch(frame)
	return patch:createInfobox()
end

return CustomPatch
