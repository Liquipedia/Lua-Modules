---
-- @Liquipedia
-- page=Module:ResultsTable/Award
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Currency = require('Module:Currency')
local DateExt = require('Module:Date/Ext')
local LeagueIcon = require('Module:LeagueIcon')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local BaseResultsTable = Lua.import('Module:ResultsTable/Base')

local AwardsTable = Class.new(BaseResultsTable)

---Builds the Header of the award table
---@return Html
function AwardsTable:buildHeader()
	local header = mw.html.create('tr')
		:tag('th'):css('width', '100px'):wikitext('Date'):done()
		:tag('th'):css('min-width', '75px'):wikitext('Tier'):done()

	if self.config.showType then
		header:tag('th'):css('min-width', '50px'):wikitext('Type')
	end

	header
		:tag('th'):css('width', '275px'):attr('colspan', 2):wikitext('Tournament'):done()
		:tag('th'):css('min-width', '225px'):wikitext('Award')

	if self.config.queryType ~= Opponent.team then
		header:tag('th'):css('min-width', '70px'):wikitext('Team')
	elseif self.config.playerResultsOfTeam then
		header:tag('th'):css('min-width', '105px'):wikitext('Player')
	end

	header:tag('th'):attr('data-sort-type', 'currency'):wikitext('Prize')

	return header
end

---Builds a row of the award table
---@param placement table
---@return Html
function AwardsTable:buildRow(placement)
	local row = mw.html.create('tr')
		:addClass(self:rowHighlight(placement))
		:tag('td'):wikitext(DateExt.toYmdInUtc(placement.date)):done()

	local tierDisplay, tierSortValue = self:tierDisplay(placement)

	row:tag('td'):attr('data-sort-value', tierSortValue):wikitext(tierDisplay)

	if self.config.showType then
		row:tag('td'):wikitext(placement.type)
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

	row:tag('td'):wikitext(placement.extradata.award)

	if self.config.playerResultsOfTeam or self.config.queryType ~= Opponent.team then
		row:tag('td'):css('text-align', 'left'):attr('data-sort-value', placement.opponentname):node(self:opponentDisplay(
			placement,
			{teamForSolo = not self.config.playerResultsOfTeam}
		))
	end

	row:tag('td'):wikitext(Currency.display('USD',
			self.config.queryType ~= Opponent.team and placement.individualprizemoney or placement.prizemoney,
			{dashIfZero = true, displayCurrencyCode = false, formatValue = true}
		))

	return row
end

return AwardsTable
