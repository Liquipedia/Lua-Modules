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
local LeagueIcon = require('Module:LeagueIcon')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local Placement = require('Module:Placement')

local BaseResultsTable = Lua.import('Module:ResultsTable/Base', {requireDevIfEnabled = true})

local Opponent = require('Module:OpponentLibraries').Opponent

--- @class ResultsTable
local ResultsTable = Class.new(BaseResultsTable)

function ResultsTable:buildHeader()
	local header = mw.html.create('tr')
		:tag('th'):css('width', '100px'):wikitext('Date'):done()
		:tag('th'):css('min-width', '80px'):wikitext('Place'):done()
		:tag('th'):css('min-width', '75px'):wikitext('Tier'):done()

	if self.config.gameIconsData then
		header:tag('th'):node(Abbreviation.make('G.', 'Game'))
	end

	header:tag('th'):css('width', '420px'):attr('colspan', 2):wikitext('Tournament')

	if self.config.queryType ~= Opponent.team then
		header:tag('th'):css('min-width', '70px'):wikitext('Team')
	elseif self.config.playerResultsOfTeam then
		header:tag('th'):css('min-width', '105px'):wikitext('Player')
	end

	if not self.config.hideResult then
		header:tag('th'):css('min-width', '105px'):attr('colspan', 2):wikitext('Result')
	end

	header:tag('th'):attr('data-sort-type', 'currency'):wikitext('Prize')

	return header
end

function ResultsTable:buildRow(placement)
	local placementCell = mw.html.create('td')
	Placement._placement{parent = placementCell, placement = placement.placement}

	local row = mw.html.create('tr')
		:addClass(self:rowHighlight(placement))
		:tag('td'):wikitext(mw.getContentLanguage():formatDate('Y-m-d', placement.date)):done()
		:node(placementCell)

	local tierDisplay, tierSortValue = self:tierDisplay(placement)

	row:tag('td'):attr('data-sort-value', tierSortValue):wikitext(tierDisplay)

	if self.config.gameIconsData then
		row:tag('th'):node(self:gameIcon(placement))
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

	if self.config.playerResultsOfTeam or self.config.queryType ~= Opponent.team then
		row:tag('td'):css('text-align', 'right'):attr('data-sort-value', placement.opponentname):node(self:opponentDisplay(
			placement,
			{flip = true, teamForSolo = not self.config.playerResultsOfTeam}
		))
	end

	if not self.config.hideResult then
		local score, vsDisplay = self:processVsData(placement)
		row
			:tag('td'):wikitext(score):done()
			:tag('td'):css('text-align', 'left'):node(vsDisplay)
	end

	row:tag('td'):css('text-align', 'right'):wikitext('$' .. Currency.formatMoney(
			self.config.queryType ~= Opponent.team and placement.individualprizemoney
			or placement.prizemoney
		))

	return row
end

return ResultsTable
