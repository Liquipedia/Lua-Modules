---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Earnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local CustomEarnings = require('Module:Earnings/Base')

local _DEFAULT_NUMBER_OF_PLAYERS_IN_TEAM = 3

function CustomEarnings.divisionFactor(mode)
    if mode == '4v4' then
        return 4
    elseif mode == '3v3' or mode == 'teamaward' then
        return 3
    elseif mode == '2v2' then
        return 2
    elseif mode == '1v1' or mode == 'individual' then
        return 1
    end

    return _DEFAULT_NUMBER_OF_PLAYERS_IN_TEAM
end

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
