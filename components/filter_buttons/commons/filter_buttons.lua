---
-- @Liquipedia
-- wiki=commons
-- page=Module:FilterButtons
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- only needed for not breaking usage from wiki code.
-- will be kicked after merge + conversion runs

local Lua = require('Module:Lua')
local FilterButtonsWidget = Lua.import('Module:Widget/FilterButtons')

local LegacyFilterButtonWrapper = {}

function LegacyFilterButtonWrapper.getFromConfig()
	return FilterButtonsWidget()
end

return LegacyFilterButtonWrapper
