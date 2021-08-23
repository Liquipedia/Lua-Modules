---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/League/Custom
--

local League = require('Module:Infobox/League')

local CustomLeague = {}

function CustomLeague.run(frame)
	local league = League(frame)
	return league:createInfobox(frame)
end

return CustomLeague
