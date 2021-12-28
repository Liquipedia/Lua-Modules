---
-- @Liquipedia
-- wiki=commons
-- page=Module:AutomaticPointsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---- This module creates a Points Table that automatically gets data from the prizepools
---- of set tournaments

local Class = require('Module:Class')
local Table = require('Module:Table')
local DivTable = require('Module:DivTable')
local Json = require('Module:Json')
local String = require('Module:StringUtils')
local Arguments = require('Module:Arguments')

function DivTable.Row:create()
	for _, cell in pairs(self.cells) do
			cell:css('border-right', '1px solid #bbbbbb')

			cell:css('text-align', 'center')
			if cell.alignLeft then
				cell:css('text-align', 'left')
			end
			self.root:node(cell)
	end

	return self.root
end

local AutomaticPointsTable = Class.new(
	function(self, frame)
		self.frame = frame
		self.args = Arguments.getArgs(frame)
	end
)

--- Main function
function AutomaticPointsTable.run(frame)
	local pointsTable = AutomaticPointsTable(frame)

	pointsTable:extractPositionBackgroundData()

	pointsTable:extractTournaments()
	pointsTable:extractTeams()

	pointsTable:queryPlacements()
	pointsTable:calculatePointsAndTotals()

	pointsTable:getSortedData()
	pointsTable:storeLPDB()

	pointsTable:setHeaders()
	local divTable = pointsTable:divTableFromData()
	return divTable
end

function AutomaticPointsTable:extractPositionBackgroundData()
	local args = self.args
	self.pbg = {}
	for _, background in Table.iter.pairsByPrefix(args, 'pbg') do
			table.insert(self.pbg, background)
	end
end

--- Extracts the tournaments while guaranteeing the order.
function AutomaticPointsTable:extractTournaments()
	local args = self.args
	self.tournaments = {}
	for argKey, argVal in pairs(args) do
		if (type(argVal) == 'string') and (string.find(argKey, 'tournament')) then
			local tournamentIndexString = String.split(argKey, 'tournament')[1]
			local tournamentIndex = tonumber(tournamentIndexString)
			local unpackedTournament = Json.parse(argVal)
			self.tournaments[tournamentIndex] = unpackedTournament
		end
	end
	return nil
end

--- Extracts the teams without guaranteeing the order.
--- Extracts the teams without guaranteeing the order.
function AutomaticPointsTable:extractTeams()
	local args = self.args
	self.teams = {}
	for argKey, argVal in pairs(args) do
		if type(argVal) == 'string' and string.find(argKey, 'team') then
			local unpackedTeam = Json.parse(argVal)
			self:unpackAliases(unpackedTeam)
			self:unpackDeductions(unpackedTeam)
			self:unpackManualPoints(unpackedTeam)
			table.insert(self.teams, unpackedTeam)
		end
	end
	return nil
end

return AutomaticPointsTable