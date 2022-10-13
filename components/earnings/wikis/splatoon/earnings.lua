---
-- @Liquipedia
-- wiki=splatoon
-- page=Module:Earnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local CustomEarnings = Lua.import('Module:Earnings/Base', {requireDevIfEnabled = true})

CustomEarnings.defaultNumberOfPlayersInTeam = 4

-- Legacy entry points
function CustomEarnings.calc_player(input)
    local args = input.args

    return CustomEarnings.calculateForPlayer(args)
end

function CustomEarnings.calc_team(input)
    local args = input.args

    return CustomEarnings.calculateForTeam(args)
end

return Class.export(CustomEarnings)
