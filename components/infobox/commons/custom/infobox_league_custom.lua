---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local CustomLeague = {}

function CustomLeague.run(frame)
	local league = League(frame)
	return league:createInfobox(frame)
end

return CustomLeague
