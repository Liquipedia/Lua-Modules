---
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

local TeamAchievements = Lua.import('Module:Infobox/Extension/Achievements')

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

	team.args.achievements = TeamAchievements.teamAll()

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
			ConditionNode(ColumnName('opponentplayers_p' .. playerIndex .. 'team'), Comparator.eq, team),
		}
	end

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDateTime),
		ConditionNode(ColumnName('prizemoney'), Comparator.gt, '0'),
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('opponentname'), Comparator.eq, team),
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

	local date = tonumber(string.sub(data.date, 1, 4)) --[[@as integer]]
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

return CustomTeam
