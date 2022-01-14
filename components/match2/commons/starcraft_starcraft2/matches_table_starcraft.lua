---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchesTable/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local CustomMatchesTable = Lua.import('Module:MatchesTable', {requireDevIfEnabled = true})

CustomMatchesTable.OpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true})
CustomMatchesTable.Opponent = Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})

return CustomMatchesTable
