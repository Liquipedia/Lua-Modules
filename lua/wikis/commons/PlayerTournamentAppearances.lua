---
-- @Liquipedia
-- page=Module:PlayerTournamentAppearances
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Condition = Lua.import('Module:Condition')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local Placement = Lua.import('Module:Placement')
local Table = Lua.import('Module:Table')
local Tournament = Lua.import('Module:Tournament')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local InputParser = Lua.import('Module:Features/TournamentAppearances/Lib/Parse')

local TournamentAppearancesTable = Lua.import('Module:Features/TournamentAppearances/Components/Table')

---@class PlayerTournamentAppearances: BaseClass
---@operator call(Frame): PlayerTournamentAppearances
---@field tournaments StandardTournament[]
local Appearances = Class.new(function(self, frame) self:init(frame) end)

---@param frame Frame
---@return string|Widget
function Appearances.run(frame)
	return Appearances(frame):create():build()
end

---@param frame Frame
---@return self
function Appearances:init(frame)
	local args = Arguments.getArgs(frame)

	self.plainArgs = args

	self.config = InputParser.readConfig(args)

	return self
end

---@return self
function Appearances:create()
	self.tournaments = Array.reverse(Tournament.getAllTournaments(InputParser.readTournamentConditionInputs(self.config)))

	if Table.isEmpty(self.tournaments) then
		return self
	end

	local pageNames = Array.map(self.tournaments, Operator.property('pageName'))
	self.players = self:_fetchPlayers(pageNames)

	return self
end

---@private
---@param pageNames string[]
---@return standardPlayer[]
function Appearances:_fetchPlayers(pageNames)
	---@type table<string, standardPlayer>
	local players = {}

	Lpdb.executeMassQuery('placement', {
		conditions = tostring(self:_placementConditions(pageNames)),
		limit = 1000,
		order = 'date asc',
		query = 'opponentplayers, opponenttype, opponentname, parent, date, placement, opponenttemplate',
	}, function (placement)
		local opponent = Opponent.fromLpdbStruct(placement)

		---@param player standardPlayer
		local function processPlayer(player)
			if Opponent.playerIsTbd(player) then
				return
			end
			local pageName = player.pageName
			---@cast pageName -nil
			if not players[pageName] then
				players[pageName] = player
				player.extradata = player.extradata or {}
				player.extradata.appearances = 0
				player.extradata.placementSum = 0
				player.extradata.results = {}
			end

			local extradata = players[pageName].extradata --[[ @as table ]]

			extradata.appearances = extradata.appearances + 1
			extradata.results[placement.parent] = {
				placement = placement.placement,
				date = placement.date,
				team = opponent.type == Opponent.team and opponent.template or player.team
			}
			local rawPlacement = Placement.raw(placement.placement)
			extradata.placementSum = extradata.placementSum + (tonumber(rawPlacement.placement[1]) or 1000)
		end

		if self.config.player then
			Array.forEach(opponent.players, processPlayer)
		end
		if self.config.staff then
			Array.forEach(Array.mapIndexes(function (index)
				return Logic.nilIfEmpty(Opponent.staffFromLpdbStruct(placement.opponentplayers, index))
			end), processPlayer)
		end
	end)

	local playersArray = Array.extractValues(players)

	if self.config.restrictToPlayersParticipatingIn then
		playersArray = Array.filter(playersArray, function(player)
			return player.extradata.results[self.config.restrictToPlayersParticipatingIn]
		end)
	end

	return Array.sortBy(
		playersArray,
		FnUtil.identity,
		---@param a standardPlayer
		---@param b standardPlayer
		---@return boolean
		function (a, b)
			local aData = a.extradata or {}
			local bData = b.extradata or {}
			if aData.appearances ~= bData.appearances then
				return aData.appearances > bData.appearances
			elseif aData.placementSum ~= bData.placementSum then
				return aData.placementSum < bData.placementSum
			end
			return a.pageName < b.pageName
		end
	)
end

---@private
---@param pageNames string[]
---@return ConditionTree
function Appearances:_placementConditions(pageNames)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionUtil.noneOf(ColumnName('opponentplayers'), {'', '[]'}),
		ConditionUtil.noneOf(ColumnName('opponentname'), {'TBD', 'Definitions', ''}),
		ConditionNode(ColumnName('mode'), Comparator.neq, 'award_individual'),
		ConditionUtil.anyOf(ColumnName('parent'), pageNames)
	}

	if self.config.restrictToFirstPrizePool then
		conditions:add(ConditionNode(ColumnName('prizepoolindex'), Comparator.eq, 1))
	end

	return conditions
end

---@return string|Widget
function Appearances:build()
	if not self.players then return 'No results found.' end

	return TournamentAppearancesTable{
		tournaments = self.tournaments,
		players = self.players,
		config = self.config,
	}
end

return Appearances
