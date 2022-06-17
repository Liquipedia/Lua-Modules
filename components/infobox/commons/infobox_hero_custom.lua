---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Hero/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Hero = require('Module:Infobox/Hero')

local CustomHero = {}

function CustomHero.run(frame)
	local hero = Hero(frame)
	return hero:createInfobox(frame)
end

return CustomHero
