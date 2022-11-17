---
-- @Liquipedia
-- wiki=commons
-- page=Module:ResultsTable/Award
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Currency = require('Module:Currency')
local LeagueIcon = require('Module:LeagueIcon')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local Opponent = require('Module:OpponentLibraries').Opponent

local BaseResultsTable = Lua.import('Module:ResultsTable/Base', {requireDevIfEnabled = true})

local AwardsTable = Class.new(BaseResultsTable)

function AwardsTable:buildHeader()
	local header = mw.html.create('tr')
		:tag('th'):css('width', '100px'):wikitext('Date'):done()
		:tag('th'):css('min-width', '75px'):wikitext('Tier'):done()
		:tag('th'):css('width', '275px'):attr('colspan', 2):wikitext('Tournament'):done()
		:tag('th'):css('min-width', '225px'):wikitext('Award'):done()

	if self.config.opponentType ~= Opponent.team then
		header:tag('th'):css('min-width', '70px'):wikitext('Team')
	elseif self.config.playerResultsOfTeam then
		header:tag('th'):css('min-width', '105px'):wikitext('Player')
	end

	header:tag('th'):attr('data-sort-type', 'currency'):wikitext('Prize')

	return header
end

function AwardsTable:buildRow(placement)
	local row = mw.html.create('tr')
		:tag('td'):wikitext(mw.getContentLanguage():formatDate('Y-m-d', placement.date)):done()

	local tierDisplay, tierSortValue = self:tierDisplay(placement)

	row:tag('td'):attr('data-sort-value', tierSortValue):wikitext(tierDisplay)

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

	row:tag('td'):css('text-align', 'left'):wikitext(placement.extradata.award)

	if self.config.playerResultsOfTeam or self.config.opponentType ~= Opponent.team then
		row:tag('td'):css('text-align', 'right'):attr('data-sort-value', placement.opponentname):node(self:opponentDisplay(
			placement,
			{flip = true, teamForSolo = not self.config.playerResultsOfTeam}
		))
	end

	row:tag('td'):css('text-align', 'right'):wikitext('$' .. Currency.formatMoney(
			self.config.opponentType ~= Opponent.team and placement.individualprizemoney
			or placement.prizemoney
		))

	return row
end

return AwardsTable
