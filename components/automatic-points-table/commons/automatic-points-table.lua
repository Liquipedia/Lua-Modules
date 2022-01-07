---
-- @Liquipedia
-- wiki=commons
-- page=Module:AutomaticPointsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Json = require('Module:Json')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local AutomaticPointsTable = Class.new(
	function(self, frame)
		self.frame = frame
		self.args = Arguments.getArgs(frame)
		self.parsedInput = self:parseInput(self.args)
	end
)

function AutomaticPointsTable.run(frame)
	local pointsTable = AutomaticPointsTable(frame)
	mw.logObject(pointsTable.parsedInput.pbg)
	mw.logObject(pointsTable.parsedInput.tournaments)
	mw.logObject(pointsTable.parsedInput.teams)

	return nil
end

function AutomaticPointsTable:parseInput(args)
	local pbg = self:parsePositionBackgroundData(args)
	local tournaments = self:parseTournaments(args)
	local teams = self:parseTeams(args)
	return {
		pbg = pbg,
		tournaments = tournaments,
		teams = teams
	}
end

--- parses the pbg arguments, these are the background colors of specific positions
--- Usually used to indicate where a team in a specific position will end up qualifying to
function AutomaticPointsTable:parsePositionBackgroundData(args)
	local pbg = {}
	for _, background in Table.iter.pairsByPrefix(args, 'pbg') do
		table.insert(pbg, background)
	end
	return pbg
end

function AutomaticPointsTable:parseTournaments(args)
	local tournaments = {}
	for _, tournament in Table.iter.pairsByPrefix(args, 'tournament') do
		table.insert(tournaments, (Json.parse(tournament)))
	end
	return tournaments
end

function AutomaticPointsTable:parseTeams(args)
	local teams = {}
	for _, team in Table.iter.pairsByPrefix(args, 'team') do
		parsedTeam = Json.parse(team)
		parsedTeam.aliases = self:parseAliases(parsedTeam)
		parsedTeam.deductions = self:parseDeductions(parsedTeam)
		parsedTeam.manualPoints = self:parseManualPoints(parsedTeam)
		table.insert(teams, parsedTeam)
	end
	return teams
end

function AutomaticPointsTable:parseAliases(team)
	local aliases = {}
	for argKey, argVal in pairs(team) do
		if type(argKey) == 'string' and string.find(argKey, 'alias%d+') then
			local aliasIndexString = String.split(argKey, 'alias')[1]
			local aliasIndex = tonumber(aliasIndexString)
			local aliasName = argVal
			aliases[aliasIndex] = aliasName
		end
	end
	return aliases
end

function AutomaticPointsTable:parseDeductions(team)
	local deductions = {}
	for argKey, argVal in pairs(team) do
		if type(argKey) == 'string' then
			if string.find(argKey, 'deduction%d+note') then
				local deductionIndex = tonumber(string.match(argKey, '%d+'))
				local deductionNote = argVal

				if not deductions[deductionIndex] then
					deductions[deductionIndex] = {}
				end

				deductions[deductionIndex].note = deductionNote
			elseif string.find(argKey, 'deduction%d+') then
				local deductionIndex = tonumber(String.split(argKey, 'deduction')[1])
				local deductionAmount = argVal

				if not deductions[deductionIndex] then
					deductions[deductionIndex] = {}
				end

				deductions[deductionIndex].amount = tonumber(deductionAmount)
			end
		end
	end
	return deductions
end

function AutomaticPointsTable:parseManualPoints(team)
	local manualPoints = {}
	for argKey, argVal in pairs(team) do
		if type(argKey) == 'string' and string.find(argKey, 'points%d+') then
			local pointsIndex = tonumber(String.split(argKey, 'points')[1])
			local points = tonumber(argVal)

			manualPoints[pointsIndex] = points
		end
	end
	return manualPoints
end

return AutomaticPointsTable