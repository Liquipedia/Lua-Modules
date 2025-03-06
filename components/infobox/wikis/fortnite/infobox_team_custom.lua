-- @Liquipedia
-- wiki=fortnite
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

---@class FortniteInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

local PLAYER_EARNINGS_ABBREVIATION = '<abbr title="Earnings of players while on the team">Player earnings</abbr>'
local MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS = 10

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
    local team = CustomTeam(frame)
    team:setWidgetInjector(CustomInjector(team))

    -- Integrate Team Medals logic directly
    team.args.achievements = team:getTeamMedals(frame)

    return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
    if id == 'earnings' then
        local playerEarnings = self.caller.totalPlayerEarnings
        table.insert(widgets, Cell{
            name = PLAYER_EARNINGS_ABBREVIATION,
            content = {playerEarnings ~= 0 and ('$' .. mw.getContentLanguage():formatNum(Math.round(playerEarnings))) or nil}
        })
    end
    return widgets
end

---@return number
---@return table<integer, number>
function CustomTeam:calculateEarnings()
    self.totalPlayerEarnings = 0

    if not Namespace.isMain() then
        return 0, {}
    end

    local team = self.pagename
    local query = 'individualprizemoney, prizemoney, opponentplayers, opponenttype, date, mode'

    local playerTeamConditions = ConditionTree(BooleanOperator.any)
    for playerIndex = 1, MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS do
        playerTeamConditions:add{
            ConditionNode(ColumnName('players_p' .. playerIndex .. 'team'), Comparator.eq, team),
        }
    end

    local conditions = ConditionTree(BooleanOperator.all):add{
        ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDateTime),
        ConditionNode(ColumnName('prizemoney'), Comparator.gt, '0'),
        ConditionTree(BooleanOperator.any):add{
            ConditionNode(ColumnName('participantlink'), Comparator.eq, team),
            ConditionTree(BooleanOperator.all):add{
                ConditionNode(ColumnName('mode'), Comparator.neq, 'team'),
                playerTeamConditions
            },
        },
    }

    local queryParameters = {
        conditions = conditions:toString(),
        query = query,
    }

    local earnings = {total = 0}

    local processPlacement = function(placement)
        self:_addPlacementToEarnings(earnings, placement)
    end

    Lpdb.executeMassQuery('placement', queryParameters, processPlacement)

    if Namespace.isMain() then
        mw.ext.LiquipediaDB.lpdb_datapoint('total_earnings_players_while_on_team_' .. team, {
            type = 'total_earnings_players_while_on_team',
            name = self.pagename,
            information = self.totalPlayerEarnings,
        })
    end

    local totalEarnings = Math.round(Table.extract(earnings, 'total'))

    return totalEarnings, earnings
end

---@param earnings table
---@param data placement
function CustomTeam:_addPlacementToEarnings(earnings, data)
    local prizeMoney = data.prizemoney

    if data.opponenttype ~= Opponent.team then
        prizeMoney = data.individualprizemoney * self:_amountOfTeamPlayersInPlacement(data.opponentplayers)
        self.totalPlayerEarnings = self.totalPlayerEarnings + prizeMoney
    end

    local date = tonumber(string.sub(data.date, 1, 4))
    earnings[date] = (earnings[date] or 0) + prizeMoney
    earnings.total = earnings.total + prizeMoney
end

---@param players table
---@return integer
function CustomTeam:_amountOfTeamPlayersInPlacement(players)
    local amount = 0
    for playerKey in Table.iter.pairsByPrefix(players, 'p') do
        if players[playerKey .. 'team'] == self.pagename then
            amount = amount + 1
        end
    end

    return amount
end

-- Integrated Team Medals logic
---@param frame Frame
---@return string
function CustomTeam:getTeamMedals(frame)
    local team = self.args.name

    if not team or team == '' then
        local currentTitle = mw.title.getCurrentTitle()
        if currentTitle and currentTitle.prefixedText then
            team = currentTitle.prefixedText
        else
            return ''
        end
    end

    if not team or team == '' then
        return ''
    end

    local resolvedTeam = mw.ext.TeamLiquidIntegration.resolve_redirect(mw.ext.TeamTemplate.teampage(team))
    team = resolvedTeam or team

    if not team then
        return ''
    end

    local function getTournamentIcon(pagename)
        local tournament = mw.ext.LiquipediaDB.lpdb('tournament', {
            limit = 1,
            conditions = '[[pagename::' .. pagename .. ']]',
            query = 'icon, icondark, name',
        })[1]
        if not tournament then
            return ''
        end
        return frame:expandTemplate{ title = 'TournamentIconSmall', args = {
            icon = tournament.icon, icondark = tournament.icondark, pagename = pagename, name = tournament.name
        }}
    end

    local function getPlacementIcons(placement)
        local condition = '[[liquipediatier::1]] AND [[liquipediatiertype::!Qualifier]] AND [[placement::' .. placement .. ']] AND ('
        for i = 1, 4 do
            if i > 1 then
                condition = condition .. ' OR '
            end
            condition = condition .. '[[opponentplayers_p' .. i .. 'team::' .. team .. ']]'
        end
        condition = condition .. ')'

        local placements = mw.ext.LiquipediaDB.lpdb('placement', {
            limit = 100,
            conditions = condition,
            query = 'pagename',
            order = 'date asc',
        })

        local icons = {}
        if type(placements) == 'table' then
            for _, placementData in pairs(placements) do
                local pagename = placementData.pagename or 'Unknown tournament'
                table.insert(icons, getTournamentIcon(pagename))
            end
        end
        return icons
    end

    local medals = {}
    for _, medal in pairs({{'1', 1}}) do
        local icons = getPlacementIcons(medal[1])
        if #icons > 0 then
            table.insert(medals, table.concat(icons, ' '))
        end
    end

    return table.concat(medals, '<br>')
end

return CustomTeam
