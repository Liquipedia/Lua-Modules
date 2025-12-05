---
-- @Liquipedia
-- page=Module:Player/Ext/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local PlayerExt = Lua.import('Module:Player/Ext')
local Table = Lua.import('Module:Table')

---@class WorldoftanksPlayerExt: PlayerExt
local CustomPlayerExt = Table.copy(PlayerExt)

--- Disabled due to common use of multi-team players (7v7/15v15)
---@return nil
function CustomPlayerExt.syncTeam()
    return nil
end

return CustomPlayerExt
