---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:PrizePool/Import/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- default custom that only "redirects" to the Base with dev option

local Lua = require('Module:Lua')
return Lua.import('Module:PrizePool/Import/Starcraft', {requireDevIfEnabled = true})
