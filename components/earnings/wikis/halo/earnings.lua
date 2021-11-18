---
-- @Liquipedia
-- wiki=halo
-- page=Module:Earnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local CustomEarnings = require('Module:Earnings/Base')

Earnings.defaultNumberOfPlayersInTeam = 3

-- Legacy entry points
function CustomEarnings.calc_player(input)
    local args = input.args

    return CustomEarnings.calculateForTeam(args)
end

function CustomEarnings.calc_team(input)
    local args = input.args

    return CustomEarnings.calculateForTeam(args)
end

return Class.export(CustomEarnings)
