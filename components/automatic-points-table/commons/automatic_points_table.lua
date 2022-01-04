---
-- @Liquipedia
-- wiki=commons
-- page=Module:AutomaticPointsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---- This module creates a Points Table that automatically gets data from the prizepools
---- of a set of selected tournaments

local Class = require('Module:Class')
local DivTable = require('Module:DivTable')
local Arguments = require('Module:Arguments')

local CustomDivTable = Class.new(DivTable)

CustomDivTable.HeaderRow = Class.new(
	CustomDivTable.Row,
	function(self)
		self.root = mw.html.create('div'):addClass('divHeaderRow')
		self.cells = {}
	end
)

function CustomDivTable.Row:create()
	for _, cell in pairs(self.cells) do
		cell:addClass('border-color-grey')
		cell:css('border-style', 'solid')
		cell:css('border-width', '1px 1px 0 0')
		cell:css('text-align', 'center')
		if cell.alignLeft then
			cell:css('text-align', 'left')
		end
		self.root:node(cell)
	end
	return self.root
end

function CustomDivTable.Row:cell(htmlNode)
	htmlNode:addClass('divCell')
	table.insert(self.cells, htmlNode)
	return self
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
	-- TODO
end
function AutomaticPointsTable:extractTournaments()
	-- TODO
end
function AutomaticPointsTable:extractTeams()
	-- TODO
end
function AutomaticPointsTable:queryPlacements()
	-- TODO
end
function AutomaticPointsTable:calculatePointsAndTotals()
	-- TODO
end
function AutomaticPointsTable:getSortedData()
	-- TODO
end
function AutomaticPointsTable:storeLPDB()
	-- TODO
end
function AutomaticPointsTable:setHeaders()
	-- TODO
end

--- create the divTable from sorted partial data
function AutomaticPointsTable:divTableFromData()
	local divTable = CustomDivTable.create()
	-- TODO
	return divTable:create()
end

return AutomaticPointsTable