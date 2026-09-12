---
-- @Liquipedia
-- page=Module:Features/SeriesMedalStatistics/Lib/Process
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Types = Lua.import('Module:Features/SeriesMedalStatistics/Types')

local THIRD = Types.optionalPlacementColumns.THIRD
local FOURTH = Types.optionalPlacementColumns.FOURTH
local SEMIFINALIST = Types.optionalPlacementColumns.SEMIFINALIST

local Processor = {}

---@param config SeriesMedalStatsConfig
---@param data {opponents: table<string, standardOpponent>, teams: table<string, string>,
---medalsData: table<string, SeriesMedalStatsDataSet>}
---@param placement any
function Processor.run(config, data, placement)
	local getIdentifier = Processor._getIdentifierByStatsType(config.statsType, data.opponents, data.teams)
	local identifier = getIdentifier(placement)
	if Logic.isEmpty(identifier) then return end
	---@cast identifier -nil

	local placementValue = placement.placement
	if config.mergeIntoSemifinalists and (placementValue == THIRD or placementValue == FOURTH) then
		placementValue = SEMIFINALIST
	end
	local cleanedPlacementValue = tonumber(placementValue) or placementValue

	data[identifier] = data[identifier] or Processor._setUpPlacementData(config.columns)
	data[identifier][cleanedPlacementValue] = data[identifier][cleanedPlacementValue] + 1
	data[identifier].total = data[identifier].total + 1
end

---@param statsType string
---@param opponents table<string, standardOpponent>
---@param teams table<string, string>
---@return fun(placement:placement):string?
function Processor._getIdentifierByStatsType(statsType, opponents, teams)
	---@param teamTemplate string
	---@return string?
	local resolveTeamToIdentifier = function(teamTemplate)
		local rawData = TeamTemplate.getRawOrNil(teamTemplate)

		if not rawData or not rawData.page then return end

		local identifier = mw.ext.TeamLiquidIntegration.resolve_redirect(rawData.page):lower()

		teams[teamTemplate] = identifier

		return identifier
	end

	if statsType == Types.statsTypes.FACTION then
		return function(placement)
			return (placement.opponentplayers or {}).p1faction
		end
	elseif statsType == Types.statsTypes.FLAG then
		return function(placement)
			return (placement.opponentplayers or {}).p1flag
		end
	elseif statsType == Types.statsTypes.PARTICIPANT then
		return function(placement)
			if placement.opponenttype == Opponent.literal or not placement.opponentname then return end

			if placement.opponenttype ~= Opponent.team then
				local identifier = placement.opponentname
				opponents[identifier] = Opponent.fromLpdbStruct(placement)

				if Opponent.isTbd(opponents[identifier]) then return end

				return identifier
			end

			local teamTemplate = placement.opponentname
			if Logic.isEmpty(teamTemplate) then
				return
			end
			---@cast teamTemplate -nil

			teamTemplate = teamTemplate:lower():gsub('_', ' ')

			local identifier = teams[teamTemplate] or resolveTeamToIdentifier(teamTemplate)
			opponents[identifier] = Opponent.fromLpdbStruct(placement)

			if Opponent.isTbd(opponents[identifier]) then return end

			return identifier
		end
	elseif statsType == Types.statsTypes.PARTICIPANT_TEAM then
		return function(placement)
			local teamTemplate = (placement.opponentplayers or {}).p1team
			if Logic.isEmpty(teamTemplate) then
				return
			end
			---@cast teamTemplate -nil

			teamTemplate = teamTemplate:lower():gsub('_', ' ')

			return teams[teamTemplate] or resolveTeamToIdentifier(teamTemplate)
		end
	end
	-- this case can not happen
	error('Invalid statsType')
end


---@param columns string[]
---@return SeriesMedalStatsDataSet
function Processor._setUpPlacementData(columns)
	return Table.map(columns, function(key, col)
		return col, 0
	end)
end

return Processor
