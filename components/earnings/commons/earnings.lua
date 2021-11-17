---
-- @Liquipedia
-- wiki=commons
-- page=Module:Earnings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Earnings = {}
local MathUtils = require('Module:Math')
local String = require('Module:StringUtils')
local Class = require('Module:Class')

---
-- Entry point for players and individuals
-- @player - the player/individual for whom the earnings shall be calculated
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
function Earnings.calculateForPlayer(args)
	local player = args.player

    if String.isEmpty(player) then
        return 0
    end
	player = mw.ext.TeamLiquidIntegration.resolve_redirect(player)

    local money = 0
    local condition = '([[players_p1::' .. player .. ']] OR'
        .. '[[players_p2::' .. player .. ']] OR'
        .. '[[players_p3::' .. player .. ']] OR'
        .. '[[players_p4::' .. player .. ']] OR'
        .. '[[players_p5::' .. player .. ']] OR'
        .. '[[players_p6::' .. player .. ']] OR'
        .. '[[players_p7::' .. player .. ']] OR'
        .. '[[players_p8::' .. player .. ']] OR'
        .. '[[players_p9::' .. player .. ']] OR'
        .. '[[players_p10::' .. player .. ']] OR'
        .. '[[participant::' .. player .. ']])'

    money = money + Earnings._calculateIndividualEarnings(condition, args.year, args.mode)

    return MathUtils._round(money)
end

function Earnings.calculateForTeam(args)
    local team = args.team
    if String.isEmpty(team) then
        return 0
    end
	team = mw.ext.TeamLiquidIntegration.resolve_redirect(team)

    local conditions = '([[participant::' .. team .. ']] OR [[extradata_participantteam::' .. team .. ']])'

    if String.isNotEmpty(args.year) then
        conditions = conditions .. ' AND [[date::>' .. args.year .. '-01-01]] AND [[date::<' .. args.year .. '-12-31]]'
    end

	if String.isNotEmpty(args.mode) then
        conditions = conditions .. ' AND [[mode::' .. args.mode .. ']]'
    end

    local money = mw.ext.LiquipediaDB.lpdb('placement', {
        conditions = '[[date::!1970-01-01 00:00:00]] AND [[prizemoney::>0]] AND ' .. conditions,
        query = 'sum::prizemoney, mode',
        groupby = 'mode asc'
    })

    local totalEarnings = 0

    for _, item in ipairs(money) do
        if item['sum_prizemoney'] ~= nil then
            local prizeMoney = item['sum_prizemoney']
            totalEarnings = totalEarnings + prizeMoney
        end
    end

    return MathUtils._round(totalEarnings)
end

---
-- Calculates earnings for this participant in a certain mode
-- @participantCondition - the condition to find the player/team
-- @year - (optional) the year to calculate earnings for
-- @mode - (optional) the mode to calculate earnings for
function Earnings._calculateIndividualEarnings(participantCondition, year, mode)
    local conditions = participantCondition

    if String.isNotEmpty(year) then
        conditions = conditions .. ' AND [[date::>' .. year .. '-01-01]] AND [[date::<' .. year .. '-12-31]]'
    end

	if String.isNotEmpty(mode) then
        conditions = conditions .. ' AND [[mode::' .. mode .. ']]'
    end

    local money = mw.ext.LiquipediaDB.lpdb('placement', {
        conditions = '[[date::!1970-01-01 00:00:00]] AND [[prizemoney::>0]] AND ' .. conditions,
        query = 'sum::prizemoney, mode',
        groupby = 'mode asc'
    })

    local totalEarnings = 0

    for _, item in ipairs(money) do
        if item['sum_prizemoney'] ~= nil then
            local prizeMoney = item['sum_prizemoney']
            totalEarnings = totalEarnings + (prizeMoney / Earnings.divisionFactor(item['mode']))
        end
    end

    return totalEarnings
end

-- overwritable in /Custom
local _DEFAULT_NUMBER_OF_PLAYERS_IN_TEAM = 5

-- overwritable in /Custom
function Earnings.divisionFactor(mode)
    if mode == '4v4' then
        return 4
    elseif mode == '3v3' then
        return 3
    elseif mode == '2v2' then
        return 2
    elseif mode == '1v1' or mode == 'individual' then
        return 1
    end

    return _DEFAULT_NUMBER_OF_PLAYERS_IN_TEAM
end

return Class.export(Earnings)
