---
-- @Liquipedia
-- page=Module:TeamCard/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')
local Variables = Lua.import('Module:Variables')

local LegacyTeamCard = {}

---@param opts table? Optional table; supports `preprocessCard` hook.
---@return string|Widget
function LegacyTeamCard.run(opts)
    opts = opts or {}
    return ''
end

return LegacyTeamCard
