---
-- @Liquipedia
-- page=Module:AutomaticPointsTable/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local POINTS_TYPE = {
	MANUAL = 'MANUAL',
	PRIZE = 'PRIZE',
	SECURED = 'SECURED'
}

local PointsDivTable = Class.new(
	function(self, pointsData, tournaments, positionBackgrounds, limit)
		self.root = mw.html.create('div') :addClass('divTable')
			:addClass('border-color-grey') :addClass('border-bottom')

		local columnCount = Array.reduce(tournaments, function(count, t)
			return count + (t.shouldDeductionsBeVisible and 2 or 1)
		end, 0)

		local innerWrapper = mw.html.create('div') :addClass('fixed-size-table-container')
			:addClass('border-color-grey')
			:css('width', tostring(450 + (columnCount * 50)) .. 'px')
			:node(self.root)

		self.wrapper = mw.html.create('div') :addClass('table-responsive')
			:addClass('automatic-points-table')
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
		self.root = mw.html.create('div') :addClass('divHeaderRow') :addClass('diagonal')
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
	-- variable cells
	Array.forEach(self.pointsData, function(points, index)
		local tournament = self.tournaments[index]
		self:pointsCell(points, tournament)
		if tournament.shouldDeductionsBeVisible then
			self:deductionCell(points.deduction)
		end
	end)

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

function TableRow:pointsCell(points, tournament)
	local finished = Logic.readBool(tournament.finished)
	local pointString = points.amount ~= nil and points.amount or (finished and '-' or '')
	local pointsCell = self:baseCell(pointString)
	if points.type == POINTS_TYPE.SECURED then
		pointsCell:css('font-weight', 'lighter'):css('font-style', 'italic')
	end
	table.insert(self.cells, pointsCell)
	return self
end

function TableRow:deductionCell(deduction)
	if Table.isEmpty(deduction) then
		table.insert(self.cells, self:baseCell(''))
		return self
	end
	local abbr = mw.html.create('abbr'):addClass('bg-down'):addClass('deduction-box')
		:wikitext(deduction.amount)
	if String.isNotEmpty(deduction.note) then
		abbr:attr('title', deduction.note)
	end
	local deductionCell = self:baseCell(abbr)
	table.insert(self.cells, deductionCell)
	return self
end

function TableHeaderRow:cell(header)
	local additionalClass = header.additionalClass

	local innerDiv = wrapInDiv(header.text) :addClass('border-color-grey')
		:addClass('content')

	local outerDiv = mw.html.create('div') :addClass('divCell')
		:addClass('diagonal-header-div-cell')
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
		text = 'Ranking',
		additionalClass = 'ranking'
	}, {
		text = 'Team',
		additionalClass = 'team'
	}, {
		text = 'Total Points'
	}}
	Array.forEach(headers, function(h) self:headerCell(h) end)
	-- variable headers (according to tournaments in given in module arguments)
	Array.forEach(self.tournaments,
		function(tournament)
			self:headerCell({
				text = tournament.display and tournament.display or tournament.name
			})

			if tournament.shouldDeductionsBeVisible then
				local deductionsHeader = tournament['deductionsheader']
				self:headerCell({
					text = deductionsHeader and deductionsHeader or 'Deductions'
				})
			end
		end
	)

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
		:addClass('diagonal-header-div-cell')

	local additionalClass = header.additionalClass
	if additionalClass then

		outerDiv:addClass(additionalClass)
	end
	outerDiv:node(innerDiv)

	table.insert(self.cells, outerDiv)
	return self
end

return PointsDivTable
