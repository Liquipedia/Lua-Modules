---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Show = Lua.import('Module:Infobox/Show', {requireDevIfEnabled = true})

local CustomShow = Class.new()

function CustomShow.run(frame)
	local customShow = Show(frame)
	return customShow:createInfobox()
end

return CustomShow
