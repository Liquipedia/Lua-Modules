---
-- @Liquipedia
-- page=Module:AutomaticPointsTable/MinifiedDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local PointsDivTable = Class.new(
	function(self, pointsData, tournaments, positionBackgrounds, limit)
		self.root = mw.html.create('div') :addClass('divTable')
			:addClass('border-color-grey') :addClass('border-bottom')

		local innerWrapper = mw.html.create('div') :addClass('fixed-size-table-container')
			:addClass('border-color-grey')
			:css('width', '316px')
			:node(self.root)

		self.wrapper = mw.html.create('div') :addClass('table-responsive')
			:addClass('automatic-points-table') :addClass('minified')
			:node(innerWrapper)

		self.rows = {}
		self.pointsData = pointsData
		self.tournaments = tournaments
		self.positionBackgrounds = positionBackgrounds
		self.limit = limit
	end
)

local TableRow = Class.new(
	function(self, pointsData, tournaments, positionBackground)
		self.root = mw.html.create('div'):addClass('divRow')
		self.cells = {}

		local team = pointsData.team
		if team.bg then
			self.root:addClass('bg-' .. team.bg)
		end

		self.pointsData = pointsData
		self.tournaments = tournaments
		self.team = team
		self.positionBackground = positionBackground
	end
)

local TableHeaderRow = Class.new(
	function(self, tournaments)
		self.tournaments = tournaments
		self.root = mw.html.create('div') :addClass('divHeaderRow')
		self.cells = {}
	end
)

function PointsDivTable:row(row)
	table.insert(self.rows, row)
	return self
end

function PointsDivTable:create()
	local headerRow = TableHeaderRow(self.tournaments)
	self:row(headerRow)

	local limit = self.limit
	Array.forEach(self.pointsData, function(teamPointsData, index)
		if index > limit then return end
		local positionBackground = self.positionBackgrounds[index]
		self:row(TableRow(teamPointsData, self.tournaments, positionBackground))
	end)

	for _, row in pairs(self.rows) do
		self.root:node(row:create())
	end

	return self.wrapper
end

function TableRow:create()
	-- fixed cells
	self:positionCell(self.pointsData.position, self.positionBackground)
	self:nameCell(self.team)
	self:totalCell(self.pointsData.totalPoints)

	for _, cell in pairs(self.cells) do
		self.root:node(cell)
	end
	return self.root
end

local function wrapInDiv(text)
	return mw.html.create('div'):wikitext(tostring(text))
end

function TableRow:baseCell(text, bg, bold)
	local div = wrapInDiv(text) :addClass('divCell') :addClass('va-middle')
		:addClass('centered-cell')	:addClass('border-color-grey') :addClass('border-top-right')

	if bg then
		div:addClass('bg-' .. bg)
	end
	if bold then
		div:css('font-weight', 'bold')
	end
	return div
end

function TableRow:totalCell(points)
	local totalCell = self:baseCell(points, nil, true)
	table.insert(self.cells, totalCell)
	return self
end

function TableRow:positionCell(position, bg)
	local positionCell = self:baseCell(position .. '.', bg, true)
	table.insert(self.cells, positionCell)
	return self
end

function TableRow:nameCell(team)
	local lastAlias = team.aliases[#team.aliases]
	local teamDisplay = team.display and team.display or mw.ext.TeamTemplate.team(lastAlias)
	local nameCell = self:baseCell(teamDisplay, team.bg):addClass('name-cell')
	table.insert(self.cells, nameCell)
	return self
end

function TableHeaderRow:cell(header)
	local additionalClass = header.additionalClass

	local innerDiv = wrapInDiv(header.text) :addClass('border-color-grey')
		:addClass('content')

	local outerDiv = mw.html.create('div') :addClass('divCell')
	if additionalClass then
		outerDiv:addClass(additionalClass)
	end
	outerDiv:node(innerDiv)
	table.insert(self.cells, outerDiv)
	return self
end

function TableHeaderRow:create()
	-- fixed headers
	local headers = {{
		text = '#',
		width = '35px'
	}, {
		text = 'Team',
		width = '225px'
	}, {
		text = 'Points',
		width = '50px'
	}}
	Array.forEach(headers, function(h) self:headerCell(h) end)

	for _, cell in pairs(self.cells) do
		self.root:node(cell)
	end
	return self.root
end

function TableHeaderRow:headerCell(header)
	local innerDiv = wrapInDiv(header.text)
		:addClass('border-color-grey')
		:addClass('content')

	local outerDiv = mw.html.create('div') :addClass('divCell')
		:addClass('border-right') :css('text-align', 'center')

	outerDiv:css('width', header.width)
	outerDiv:node(innerDiv)

	table.insert(self.cells, outerDiv)
	return self
end

return PointsDivTable
