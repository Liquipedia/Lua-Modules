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
		self:parseInput()
	end
)

function AutomaticPointsTable.run(frame)
	local pointsTable = AutomaticPointsTable(frame)


	mw.logObject(pointsTable.pbg)
	mw.logObject(pointsTable.tournaments)

	return nil
end

--- parses the pbg arguments, these are the background colors of specific positions
--- Usually used to indicate where a team in a specific position will end up qualifying to
function AutomaticPointsTable:parsePositionBackgroundData()
	local args = self.args
	self.pbg = {}
	for _, background in Table.iter.pairsByPrefix(args, 'pbg') do
		table.insert(self.pbg, background)
	end
end

function AutomaticPointsTable:parseTournaments()
	local args = self.args
	self.tournaments = {}
	for _, tournament in Table.iter.pairsByPrefix(args, 'tournament') do
		table.insert(self.tournaments, (Json.parse(tournament)))
	end
	return nil
end

return AutomaticPointsTable