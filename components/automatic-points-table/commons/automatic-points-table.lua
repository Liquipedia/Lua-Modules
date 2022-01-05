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
	end
)

function AutomaticPointsTable.run(frame)
	local pointsTable = AutomaticPointsTable(frame)

	pointsTable:extractPositionBackgroundData()

	pointsTable:extractTournaments()

	mw.logObject(pointsTable.pbg)
	mw.logObject(pointsTable.tournaments)

	return nil
end

function AutomaticPointsTable:extractPositionBackgroundData()
	local args = self.args
	self.pbg = {}
	for _, background in Table.iter.pairsByPrefix(args, 'pbg') do
		table.insert(self.pbg, background)
	end
end

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

return AutomaticPointsTable