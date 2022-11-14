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
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local BaseResultsTable = Lua.import('Module:ResultsTable/Base', {requireDevIfEnabled = true})

local Opponent = require('Module:OpponentLibraries').Opponent

local SCORE_CONCAT = '&nbsp;&#58;&nbsp;'

--- @class ResultsTable
local ResultsTable = Class.new(BaseResultsTable)

function ResultsTable:buildHeader()
	local header = mw.html.create('tr')
		:tag('th'):css('width', '100px'):wikitext('Date'):done()
		:tag('th'):css('min-width', '80px'):wikitext('Place'):done()
		:tag('th'):css('min-width', '75px'):wikitext('Tier'):done()

	if self.config.gameIconsData then
		header:tag('th'):node(Abbreviation.make('G.', 'Game')):done()
	end

	header:tag('th'):css('width', '420px'):attr('colspan', 2):wikitext('Tournament'):done()

	if self.config.queryType ~= Opponent.team then
		header:tag('th'):css('min-width', '70px'):wikitext('Team'):done()
	elseif self.config.playerResultsOfTeam then
		header:tag('th'):css('min-width', '105px'):wikitext('Player'):done()
	end

	if not self.config.hideResult then
		header:tag('th'):css('min-width', '105px'):attr('colspan', 2):wikitext('Result'):done()
	end

	header:tag('th'):attr('data-sort-type', 'currency'):wikitext('Prize'):done()

	return header:done()
end

function ResultsTable:buildRow(placement)
	local placementCell = mw.html.create('td')
	Placement._placement{parent = placementCell, placement = placement.placement}
	placementCell:done()

	local row = mw.html.create('tr')
		:addClass(self:rowHighlight(placement))
		:tag('td'):wikitext(placement.date:sub(1, 10)):done()
		:node(placementCell)

	local tierDisplay, tierSortValue = self:tierDisplay(placement)

	row
		:tag('td'):attr('data-sort-value', tierSortValue):wikitext(tierDisplay):done()

	if self.config.gameIconsData then
		header:tag('th'):node(self:gameIcon(placement)):done()
	end

	local tournamentDisplayName = BaseResultsTable.tournamentDisplayName(placement)

	row
		:tag('td'):css('width', '30px'):attr('data-sort-value', tournamentDisplayName):wikitext(LeagueIcon.display{
			icon = placement.icon,
			iconDark = placement.icondark,
			link = placement.parent,
			name = displayName,
			options = {noTemplate = true},
		}):done()
		:tag('td'):attr('data-sort-value', tournamentDisplayName):css('text-align', 'left'):wikitext(Page.makeInternalLink(
			{},
			tournamentDisplayName,
			placement.pagename
		)):done()

	if self.config.playerResultsOfTeam or self.config.queryType ~= Opponent.team then
		row:tag('td'):css('text-align', 'right'):attr('data-sort-value', placement.opponentname):node(self:opponentDisplay(
			placement,
			{flip = true, teamForSolo = not self.config.playerResultsOfTeam}
		)):done()
	end

	if not self.config.hideResult then
		local score, vsDisplay = self:_processVsData(placement)
		row
			:tag('td'):wikitext(score):done()
			:tag('td'):css('text-align', 'left'):node(vsDisplay):done()
	end

	row:tag('td'):css('text-align', 'right'):wikitext('$' .. Currency.formatMoney(
			self.config.queryType ~= Opponent.team and placement.individualprizemoney
			or placement.prizemoney
		)):done()

	return row:done()
end

--[[
proposed data structure for lastvsdata:

local lastvsdata = Json.stringify(Table.merge(
		opponent.additionalData.LASTVS and Opponnet.toLpdbStruct(opponent.additionalData.LASTVS) or {},
		{score = (opponent.additionalData.LASTVSSCORE or {}).vsscore, groupscore = opponent.additionalData.GROUPSCORE}
	))
]]
function ResultsTable:_processVsData(placement)
	local lastVs
	if Table.isEmpty(placement.lastvsdata) then
		lastVs = self:processLegacyVsData(placement)
	else
		lastVs = placement.lastvsdata
	end

	if String.isNotEmpty(lastVs.groupscore) then
		return placement.groupscore, Abbreviation.make('Grp S.', 'Group Stage')
	end

	local score = (placement.lastscore or '-') .. SCORE_CONCAT .. (lastVs.score or '-')
	local vsDisplay = self:opponentDisplay(lastVs, {})

	return score, vsDisplay
end

-- overwritable
function ResultsTable:processLegacyVsData(placement)
	local lastVs = {score = placement.lastvsscore, groupscore = placement.groupscore}
	-- lets assume opponentType of the vs opponent is the same as of the opponent
	lastVs.opponenttype = placement.opponenttype
	-- assume lastvs is team template for teams and pagename & displayname for players
	-- if wikis store them in extradata they can overwrite this function until lastvsdata field is filled
	lastVs.opponentplayers = {p1 = placement.lastvs, p1dn = placement.lastvs}
	lastVs.opponenttemplate = placement.lastvs

	return lastVs
end

-- overwritable
-- shadows the current implementation
-- todo: in the future change it to use darkmode icons too
-- needs upgrading the game icon data modules first though
function ResultsTable:gameIcon(placement)
	local gameIcon = self.config.gameIconsData[placement.game] or 'Logo filler event.png'
	gameIcon = gameIcon:gsub('File:', '')
	return LeagueIcon.display{
		icon = gameIcon,
		options = {noTemplate = true, noLink = true},
	}
end

return ResultsTable
