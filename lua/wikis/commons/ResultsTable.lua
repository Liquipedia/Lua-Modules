---
-- @Liquipedia
-- wiki=commons
-- page=Module:ResultsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Class = require('Module:Class')
local Currency = require('Module:Currency')
local DateExt = require('Module:Date/Ext')
local Game = require('Module:Game')
local LeagueIcon = require('Module:LeagueIcon')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Placement = require('Module:Placement')
local Table = require('Module:Table')

local BaseResultsTable = Lua.import('Module:ResultsTable/Base')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

--- @class ResultsTable: BaseResultsTable
local ResultsTable = Class.new(BaseResultsTable)

---Builds the Header of the results/achievements table
---@return Html
function ResultsTable:buildHeader()
	local header = mw.html.create('tr')
		:tag('th'):css('width', '100px'):wikitext('Date'):done()
		:tag('th'):css('min-width', '80px'):wikitext('Place'):done()
		:tag('th'):css('min-width', '75px'):wikitext('Tier'):done()

	if self.config.showType then
		header:tag('th'):css('min-width', '50px'):wikitext('Type')
	end

	if self.config.displayGameIcons then
		header:tag('th'):node(Abbreviation.make{text = 'G.', title = 'Game'})
	end

	header:tag('th'):css('width', '420px'):attr('colspan', 2):wikitext('Tournament')

	if self.config.queryType ~= Opponent.team or Table.isNotEmpty(self.config.aliases) then
		header:tag('th'):css('min-width', '70px'):wikitext('Team')
	elseif self.config.playerResultsOfTeam then
		header:tag('th'):css('min-width', '105px'):wikitext('Player')
	end

	if not self.config.hideResult then
		header:tag('th'):css('min-width', '105px'):attr('colspan', 2):addClass('unsortable'):wikitext('Result')
	end

	header:tag('th'):attr('data-sort-type', 'currency'):wikitext('Prize')

	return header
end

---Builds a placement row of the results/achievements table
---@param placement table
---@return Html
function ResultsTable:buildRow(placement)
	local placementCell = mw.html.create('td')
	Placement._placement{parent = placementCell, placement = placement.placement}

	local row = mw.html.create('tr')
		:addClass(self:rowHighlight(placement))
		:tag('td'):wikitext(DateExt.toYmdInUtc(placement.date)):done()
		:node(placementCell)

	local tierDisplay, tierSortValue = self:tierDisplay(placement)

	row:tag('td'):attr('data-sort-value', tierSortValue):wikitext(tierDisplay)

	if self.config.showType then
		row:tag('td'):wikitext(placement.type)
	end

	if self.config.displayGameIcons then
		row:tag('td'):node(Game.icon{game = placement.game})
	end

	local tournamentDisplayName = BaseResultsTable.tournamentDisplayName(placement)

	row
		:tag('td'):css('width', '30px'):attr('data-sort-value', tournamentDisplayName):wikitext(LeagueIcon.display{
			icon = placement.icon,
			iconDark = placement.icondark,
			link = placement.parent,
			name = tournamentDisplayName,
			options = {noTemplate = true},
		}):done()
		:tag('td'):attr('data-sort-value', tournamentDisplayName):css('text-align', 'left'):wikitext(Page.makeInternalLink(
			{},
			tournamentDisplayName,
			placement.pagename
		))

	if self.config.playerResultsOfTeam or
		self.config.queryType ~= Opponent.team or
		Table.isNotEmpty(self.config.aliases) then

		row:tag('td'):css('text-align', self.config.hideResult and 'left' or 'right')
			:attr('data-sort-value', placement.opponentname)
			:node(self:opponentDisplay(placement,
			{teamForSolo = not self.config.playerResultsOfTeam, flip = not self.config.hideResult}
		))
	end

	if not self.config.hideResult then
		local score, vsDisplay, groupAbbr = self:processVsData(placement)
		row
			:tag('td'):wikitext(score):done()
			:tag('td'):css('text-align', 'left'):cssText(groupAbbr and 'padding-left:14px' or nil):node(vsDisplay or groupAbbr)
	end

	local useIndivPrize = self.config.useIndivPrize and self.config.queryType ~= Opponent.team
	row:tag('td'):wikitext(Currency.display('USD',
			useIndivPrize and placement.individualprizemoney or placement.prizemoney,
			{dashIfZero = true, displayCurrencyCode = false, formatValue = true}
		))

	return row
end

return ResultsTable
