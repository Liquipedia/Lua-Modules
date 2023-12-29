---
-- @Liquipedia
-- wiki=fortnite
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
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
local EARNINGS_MODES = {team = 'team'}

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))

	return team:createInfobox()
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.earnings = self.totalEarnings

	return lpdbData
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'earnings' then
		local earningsWhileOnTeam
		self.caller.totalEarnings, earningsWhileOnTeam = self.caller:calculateEarnings()
		local earningsDisplay
		if self.caller.totalEarnings == 0 then
			earningsDisplay = nil
		else
			earningsDisplay = '$' .. mw.language.new('en'):formatNum(self.caller.totalEarnings)
		end
		local earningsFromPlayersDisplay
		if earningsWhileOnTeam > 0 then
			earningsFromPlayersDisplay = '$' .. mw.language.new('en'):formatNum(earningsWhileOnTeam)
		end
		return {
			Cell{name = 'Approx. Total Winnings', content = {earningsDisplay}},
			Cell{name = PLAYER_EARNINGS_ABBREVIATION, content = {earningsFromPlayersDisplay}},
		}
	end
	return widgets
end

---@return number
---@return number
function CustomTeam:calculateEarnings()
	if not Namespace.isMain() then
		return 0, 0
	end

	local team = self.pagename
	local query = 'individualprizemoney, prizemoney, players, date, mode'

	local playerTeamConditions = ConditionTree(BooleanOperator.any)
	for playerIndex = 1, MAXIMUM_NUMBER_OF_PLAYERS_IN_PLACEMENTS do
		playerTeamConditions:add{
			ConditionNode(ColumnName('players_p' .. playerIndex .. 'team'), Comparator.eq, team),
		}
	end

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.neq, '1970-01-01 00:00:00'),
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

	local earnings = {total = {}}
	local playerEarnings = 0

	local processPlacement = function(placement)
		earnings, playerEarnings = self:_addPlacementToEarnings(earnings, playerEarnings, placement)
	end

	Lpdb.executeMassQuery('placement', queryParameters, processPlacement)

	if earnings.team == nil then
		earnings.team = {}
	end

	if Namespace.isMain() then
		mw.ext.LiquipediaDB.lpdb_datapoint('total_earnings_players_while_on_team_' .. team, {
				type = 'total_earnings_players_while_on_team',
				name = self.pagename,
				information = playerEarnings,
		})
	end

	Variables.varDefine('earnings', earnings.team.total or 0)

	return Math.round(earnings.team.total or 0), Math.round(playerEarnings or 0)
end

---@param earnings table
---@param playerEarnings number
---@param data placement
---@return table
---@return number
function CustomTeam:_addPlacementToEarnings(earnings, playerEarnings, data)
	local prizeMoney = data.prizemoney
	data.players = data.players or {}
	local mode = data.players.type or data.mode or ''
	mode = EARNINGS_MODES[mode]
	if not mode then
		prizeMoney = data.individualprizemoney * self:_amountOfTeamPlayersInPlacement(data.players)
		playerEarnings = playerEarnings + prizeMoney
		mode = 'other'
	end
	if not earnings[mode] then
		earnings[mode] = {}
	end
	local date = string.sub(data.date, 1, 4)
	earnings[mode][date] = (earnings[mode][date] or 0) + prizeMoney
	earnings[mode]['total'] = (earnings[mode]['total'] or 0) + prizeMoney
	earnings['total'][date] = (earnings['total'][date] or 0) + prizeMoney

	return earnings, playerEarnings
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

return CustomTeam
