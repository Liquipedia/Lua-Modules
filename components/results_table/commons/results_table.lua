---
-- @Liquipedia
-- wiki=commons
-- page=Module:ResultsTable/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
--local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local DEFAULT_VALUES = {
	order = 'desc',
	playerPrefix = 'p',
	coachPrefix = 'c',
	resolveOpponent = true,
	playerLimit = 10,
	coachLimit = 5,
	achievementsLimit = 10,
	resultsLimit = 5000,
}
local SOLO_TYPE = 'solo'
local TEAM_TYPE = 'team'
local COACH_TYPE = 'coach'
local VALID_QUERY_TYPES = {
	SOLO_TYPE,
	TEAM_TYPE,
	COACH_TYPE,
}

--- @class BaseResultsTable
local BaseResultsTable = Class.new(function(self, ...) self:init(...) end)

function BaseResultsTable:init(args)
	self.args = args

	self.pagename = mw.title.getCurrentTitle().text

	self.config = self:readConfig()

	return self
end

function BaseResultsTable:readConfig()
	local args = self.args

	local config = {
		order = args.order or DEFAULT_VALUES.order,
		playerPrefix = args.prefixplayer or DEFAULT_VALUES.playerPrefix,
		coachPrefix = args.prefixcoach or DEFAULT_VALUES.coachPrefix,
		hideResult = Logic.readBool(args.hideresult),
		resolveOpponent = Logic.readBool(args.resolve or DEFAULT_VALUES.resolveOpponent),
		gameIconsData = args.gameIcons and mw.loadData(args.gameIcons) or nil,
		opponent = mw.text.decode(args.coach or args.player or args.team or self:_getOpponent()),
		queryType = self:getQueryType(),
		onlyAchievements = Logic.readBool(args.achievements),
		playerResultsOfTeam = Logic.readBool(args.playerResultsOfTeam),
	}

	config.sort = args.sort or
		(config.onlyAchievements and 'weight' or 'date')

	config.limit = tonumber(args.limit) or
		(config.onlyAchievements and DEFAULT_VALUES.achievementsLimit or DEFAULT_VALUES.resultsLimit)

	config.playerLimit =
		(config.queryType == SOLO_TYPE and tonumber(args.playerLimit) or DEFAULT_VALUES.playerLimit)
		or (config.queryType == COACH_TYPE and tonumber(args.coachLimit) or DEFAULT_VALUES.coachLimit)

	return config
end

function BaseResultsTable:_getOpponent()
	if Namespace.isMain() then
		return mw.title.getCurrentTitle().baseText
	elseif String.contains(mw.title.getCurrentTitle().subpageText:lower(), 'results') then
		local pageName = mw.text.split(mw.title.getCurrentTitle().text, '/')
		return pageName[#pageName - 1]
	end

	return mw.title.getCurrentTitle().subpageText
end

function BaseResultsTable:getQueryType()
	local args = self.args

	if args.querytype then
		local queryType = args.querytype:lower()
		if Table.includes(VALID_QUERY_TYPES, queryType) then
			return queryType
		end
	end

	error('Invalid querytype "' .. (args.querytype or '') .. '"')
end

function BaseResultsTable:create()
	local data = self.args.data or self:queryData()

	if Table.isEmpty(data) then
		return
	end

	table.sort(data, function(placement1, placement2) return placement1.date > placement2.date end)

	if self.config.onlyAchievements then
		self.data = {data}
		return self
	end

	-- split placements into years for non achievements
	local splitData = Array.groupBy(data, function(placementData)
		return placementData.date:sub(1,4)
	end)

	-- Set the header
	Table.iter.forEach(splitData, function(dataSet)
		dataSet.header = dataSet[1].date:sub(1,4)
	end)

	Array.sortInPlaceBy(splitData, function(val) return val.header end, function(val1, val2) return val1 > val2 end)
	self.data = splitData

	return self
end

function BaseResultsTable:queryData()
	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = self.config.limit,
		order = self.config.sort .. ' ' .. self.config.order,
		conditions = self:buildConditions(),
	})

	if type(data) ~= 'table' then
		error(data)
	end

	return data
end

function BaseResultsTable:buildConditions()
	if self.args.customConditions then
		return self.args.customConditions
	end

	local conditions = self:buildBaseConditions()

	if self.args.additionalConditions then
		return conditions .. self.args.additionalConditions
	end

	return conditions
end

function BaseResultsTable:buildBaseConditions()
	local args = self.args

	local conditions = ConditionTree(BooleanOperator.all)
		:add{self:buildOpponentConditions()}

	if args.game then
		conditions:add{ConditionNode(ColumnName('game'), Comparator.eq, args.game)}
	end

	local startDate = args.startdate or args.sdate
	if startDate then
		-- intentional > here to keep it as is in current modules
		-- possibly change to >= later
		conditions:add{ConditionNode(ColumnName('date'), Comparator.gt, startDate)}
	end

	local endDate = args.enddate or args.edate
	if endDate then
		-- intentional < here to keep it as is in current modules
		-- possibly change to <= later
		conditions:add{ConditionNode(ColumnName('date'), Comparator.lt, endDate)}
	end

	if args.placement then
		conditions:add{ConditionNode(ColumnName('placement'), Comparator.eq, args.placement)}
	elseif not Logic.readBool(args.ignorePlacement) then
		conditions:add{ConditionNode(ColumnName('placement'), Comparator.neq, '')}
	end

	if args.tier then
		local tierConditions = ConditionTree(BooleanOperator.any)
		for _, tier in pairs(mw.text.split(args.tier, ',%s?')) do
			tierConditions:add{ConditionNode(ColumnName('liquipediatier'), Comparator.eq, tier)}
		end
		conditions:add{tierConditions}
	end

	return conditions:toString()
end

-- todo: adjust once #1802 is done
function BaseResultsTable:buildOpponentConditions()
	local config = self.config
	local opponent = config.opponent

	local opponentConditions = ConditionTree(BooleanOperator.any)

	if config.queryType == SOLO_TYPE or config.queryType == COACH_TYPE then
		opponent = config.resolveOpponent
			and mw.ext.TeamLiquidIntegration.resolve_redirect(opponent)
			or opponent

		local opponentWithUnderscore = opponent:gsub(' ', '_')

		local prefix
		if config.queryType == SOLO_TYPE then
			prefix = config.playerPrefix
			opponentConditions:add{
				ConditionTree(BooleanOperator.all):add{
					ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.solo),
					ConditionNode(ColumnName('opponentname'), Comparator.eq, opponent),
				},
				ConditionTree(BooleanOperator.all):add{
					ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.solo),
					ConditionNode(ColumnName('opponentname'), Comparator.eq, opponentWithUnderscore),
				},
			}
		else
			prefix = config.coachPrefix
		end

		for playerIndex = 1, config.playerLimit do
			opponentConditions:add{
				ConditionNode(ColumnName('opponentplayers_' .. prefix .. playerIndex), Comparator.eq, opponent),
				ConditionNode(ColumnName('opponentplayers_' .. prefix .. playerIndex), Comparator.eq, opponentWithUnderscore),
			}
		end

		return opponentConditions
	end

	opponent = Team.queryDB('teampage', opponent)
	if not opponent then
		error('Missing team template for team: ' .. opponent)
	end

	local opponentPageNames = {}
	if config.resolveOpponent then
		opponent = Team.queryDB('teampage', mw.ext.TeamLiquidIntegration.resolve_redirect(opponent))
		if not opponent then
			error('Missing team template for team: ' .. opponent)
		end
		table.insert(opponentPageNames, opponent)
	elseif Team.queryHistoricalNames then
		opponentPageNames = Team.queryHistoricalNames(opponent)
	else
		table.insert(opponentPageNames, opponent)
	end

	if config.playerResultsOfTeam then
		local prefix = config.playerPrefix
		for _, pageName in pairs(opponentPageNames) do
			local pageNameWithUnderScore = pageName:gsub(' ', '_')
			for playerIndex = 1, config.playerLimit do
				opponentConditions:add{
					ConditionNode(ColumnName('opponentplayers_' .. prefix .. playerIndex .. 'team'), Comparator.eq, pageName),
					ConditionNode(
						ColumnName('opponentplayers_' .. prefix .. playerIndex .. 'team'),
						Comparator.eq,
						pageNameWithUnderScore
					),
				}
			end
		end

		return ConditionTree(BooleanOperator.all):add{
			opponentConditions,
			ConditionNode(ColumnName('opponenttype'), Comparator.neq, Opponent.team),
		}
	end

	for _, pageName in pairs(opponentPageNames) do
		opponentConditions:add{
			ConditionNode(ColumnName('opponentname'), Comparator.eq, pageName),
			ConditionNode(ColumnName('opponentname'), Comparator.eq, pageName:gsub(' ', '_')),
		}
	end

	return ConditionTree(BooleanOperator.all):add{
			opponentConditions,
			ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
		}
end

-- todo:
-- > build display from config and data

return BaseResultsTable
