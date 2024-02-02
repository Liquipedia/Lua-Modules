---
-- @Liquipedia
-- wiki=commons
-- page=Module:ChampionMatchTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Custom')
local VodLink = require('Module:VodLink')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local CHAMPION_NOT_FOUND = 0

local INVALID_TIER_DISPLAY = 'Undefined'
local INVALID_TIER_SORT = 'ZZ'

---@class ChampionMatchTableConfig
---@field limit number
---@field showType boolean
---@field showMap boolean

---@class GameRecord
---@field date string
---@field winner number
---@field pickedBy number
---@field scores number[]
---@field participants table
---@field type string
---@field game string?
---@field vod string?
---@field map string?
---@field length string?
---@field extradata table?

---@class MatchRecord
---@field date string
---@field timestamp number
---@field liquipediatier string?
---@field liquipediatiertype string?
---@field displayName string
---@field icon string?
---@field iconDark string?
---@field pageName string
---@field type string
---@field vod string?
---@field opponents match2opponent[]
---@field games GameRecord[]

---@class ChampionMatchTable
---@operator call(table): ChampionMatchTable
---@field args table
---@field champion string
---@field config ChampionMatchTableConfig
---@field matches MatchRecord[]
local ChampionMatchTable = Class.new(
	function(self, args)
		self.args = args or {}
		self.champion = args.champion or string.gsub(mw.title.getCurrentTitle().text, '/Matches', '')
		self.matches = {}
	end
)

function ChampionMatchTable:readConfig()
	local args = self.args

	self.config = {
		limit = tonumber(args.limit) or 200,
		showType = Logic.readBool(args.showType),
		showMap = Logic.readBool(args.showMap)
	}
end

---Returns the opponentIndex of who picked the Champion (return 0 if not found)
---@param record table
---@return number
function ChampionMatchTable:findWhoPickedChampion(record)
	return CHAMPION_NOT_FOUND
end

---@param record table
---@return GameRecord?
function ChampionMatchTable:_gameFromRecord(record)
	local pickedBy = self:findWhoPickedChampion(record)
	if pickedBy == CHAMPION_NOT_FOUND then
		return nil
	end

	local gameRecord = {
		date = record.date,
		winner = tonumber(record.winner),
		pickedBy = pickedBy,
		scores = record.scores,
		type = record.type,
		participants = record.participants,
		game = record.game,
		vod = record.vod,
		map = record.map,
		length = record.length,
		extradata = record.extradata or {},
	}

	return gameRecord
end

---@param record table
---@return MatchRecord
function ChampionMatchTable:_matchFromRecord(record)
	record.extradata = record.extradata or {}

	local matchRecord = {
		timestamp = record.extradata.timestamp or DateExt.readTimestamp(record.date),
		liquipediatier = record.liquipediatier,
		liquipediatiertype = record.liquipediatiertype,
		displayName = Logic.emptyOr(String.nilIfEmpty(record.tickername),
			String.nilIfEmpty(record.tournament), record.pagename:gsub('_', ' ')),
		icon = String.nilIfEmpty(record.icon),
		iconDark = String.nilIfEmpty(record.icondark),
		pageName = String.nilIfEmpty(record.pagename) or String.nilIfEmpty(record.parent),
		type = record.type,
		vod = record.vod,
		opponents = record.match2opponents,
		games = {},
	}

	Array.forEach(record.match2games, function (game)
		table.insert(matchRecord.games, self:_gameFromRecord(game))
	end)

	return matchRecord
end

---@return ConditionTree?
function ChampionMatchTable:buildChampionConditions()
	return nil
end

---@return string
function ChampionMatchTable:buildGameConditions()
	local championConditions = self:buildChampionConditions()
	return ConditionTree(BooleanOperator.all)
		:add(ConditionNode(ColumnName('winner'), Comparator.notEquals, ''))
		:add(ConditionNode(ColumnName('mode'), Comparator.equals, 'team'))
		:add(championConditions)
		:toString()
end

---@return string
function ChampionMatchTable:_buildMatchConditions()
	local lpdbData = mw.ext.LiquipediaDB.lpdb('match2game', {
		conditions = self:buildGameConditions(),
		query = 'match2id',
		order = 'date desc',
		groupby = 'match2id asc',
		limit = self.config.limit
	})

	local conditions = ConditionTree(BooleanOperator.any)
	Array.forEach(lpdbData, function (game)
		conditions:add(ConditionNode(ColumnName('match2id'), Comparator.eq, game.match2id))
	end)

	return conditions:toString()
end

function ChampionMatchTable:query()
	local matchConditions = self:_buildMatchConditions()
	local lpdbData = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = matchConditions,
		query = 'match2opponents, match2games, date, icon, icondark, liquipediatier, game, type, '
			.. 'liquipediatiertype, tournament, parent, pagename, tickername, vod, extradata',
		order = 'date desc',
		limit = self.config.limit
	})

	Array.forEach(lpdbData, function (match)
		table.insert(self.matches, self:_matchFromRecord(match))
	end)
end

---@param text string?
---@param width string?
---@return Html
function ChampionMatchTable:_buildHeaderCell(text, width)
	return mw.html.create('th')
		:css(text and 'max-width' or 'width', width)
		:node(text)
end

function ChampionMatchTable:buildHeaderRow()
	local header = mw.html.create('tr')
		:node(self:_buildHeaderCell('Date', '100px'))
		:node(self:_buildHeaderCell('Tier', '70px'))
		:node(self.config.showType and self:_buildHeaderCell('Type', '50px') or nil)
		:node(self:_buildHeaderCell(nil, '25px'):addClass('unsortable'))
		:node(self:_buildHeaderCell('Tournament'))
		:node(self.config.showMap and self:_buildHeaderCell('Map', '80px') or nil)
		:node(self:_buildHeaderCell('Team'))
		:node(self:_buildHeaderCell('Score'))
		:node(self:_buildHeaderCell('vs. Team'))
		:node(self:_buildHeaderCell('Vod'))

	return header
end

---@param game GameRecord
---@return string
function ChampionMatchTable:_getBackgroundClass(game)
	if game.winner == 0 then
		return 'bg-draw'
	end

	return game.winner == game.pickedBy and 'bg-up' or 'bg-down'
end

---@param match MatchRecord
---@return Html
function ChampionMatchTable:_buildDateCell(match)
	return mw.html.create('td')
		:css('text-align', 'left')
		:node(DateExt.formatTimestamp('Y-m-d', match.timestamp or ''))
end

---@param match MatchRecord
---@return Html
function ChampionMatchTable:_buildTierCell(match)
	local tier, tierType, options = Tier.parseFromQueryData(match)
	options.link = true
	options.onlyTierTypeIfBoth = true

	if not Tier.isValid(tier, tierType) then
		return mw.html.create('td')
			:attr('data-sort-value', INVALID_TIER_DISPLAY)
			:wikitext(INVALID_TIER_SORT)
	end

	return mw.html.create('td')
		:attr('data-sort-value', Tier.toSortValue(tier, tierType))
		:wikitext(Tier.display(tier, tierType, options))
end

---@param match MatchRecord
---@return Html?
function ChampionMatchTable:_buildTypeCell(match)
	if not self.config.showType then
		return nil
	end

	return mw.html.create('td')
		:wikitext(match.type)
end

---@param match MatchRecord
---@return Html
function ChampionMatchTable:_buildIconCell(match)
	return mw.html.create('td')
		:node(LeagueIcon.display{
			icon = match.icon,
			iconDark = match.iconDark,
			link = match.pageName,
			name = match.displayName,
			options = {noTemplate = true},
		})
end

---@param match MatchRecord
---@return Html
function ChampionMatchTable:_buildTournamentCell(match)
	return mw.html.create('td')
		:css('text-align', 'left')
		:css('max-width', '400px')
		:wikitext(Page.makeInternalLink(match.displayName, match.pageName))
end

---@param game GameRecord
---@return Html?
function ChampionMatchTable:_buildMapCell(game)
	if not self.config.showMap then
		return nil
	end

	return mw.html.create('td')
		:node(Page.makeInternalLink(game.map))
end

---@param opponentRecord match2opponent
---@param flipped boolean?
---@return Html|string
function ChampionMatchTable:_getOpponentDiplay(opponentRecord, flipped)
	local opponent = Opponent.fromMatch2Record(opponentRecord)

	if Logic.isEmpty(opponent) then
		return 'Unknown'
	end

	return OpponentDisplay.BlockOpponent{
		opponent = opponent --[[@as standardOpponent]],
		flip = flipped,
		overflow = 'wrap',
		teamStyle = 'icon',
	}
end

---@param opponent match2opponent
---@param oppIndex number
---@param game GameRecord
---@param flipped boolean?
---@return Html
function ChampionMatchTable:buildOpponentCell(opponent, oppIndex, game, flipped)
	return mw.html.create('td')
end

---@param game GameRecord
---@return Html
function ChampionMatchTable:buildScoreCell(game)
	return mw.html.create('td')
end

---@param vod string?
---@return Html
function ChampionMatchTable:_buildVodCell(vod)
	local cell = mw.html.create('td')

	if Logic.isEmpty(vod) then
		return cell:wikitext('')
	end
	return  cell:node(VodLink.display{vod = vod --[[@as string]]})
end

---@param match MatchRecord
---@param game GameRecord
---@return Html
function ChampionMatchTable:buildRow(match, game)
	local vsIndex = game.pickedBy == 1 and 2 or 1

	local row = mw.html.create('tr')
		:addClass(self:_getBackgroundClass(game))
		:node(self:_buildDateCell(match))
		:node(self:_buildTierCell(match))
		:node(self:_buildTypeCell(match))
		:node(self:_buildIconCell(match))
		:node(self:_buildTournamentCell(match))
		:node(self:_buildMapCell(game))
		:node(self:buildOpponentCell(match.opponents[game.pickedBy], game.pickedBy, game))
		:node(self:buildScoreCell(game))
		:node(self:buildOpponentCell(match.opponents[vsIndex], vsIndex, game, true))
		:node(self:_buildVodCell(Logic.emptyOr(game.vod, match.vod)))

	return row
end

---@return Html
function ChampionMatchTable:build()
	local displayTable = mw.html.create('table')
		:addClass('wikitable wikitable-striped sortable')
		:css('text-align', 'center')
		:node(self:buildHeaderRow())

	if Table.isEmpty(self.matches) then
		return displayTable:node(mw.html.create('tr')
			:tag('td'):attr('colspan', 42):wikitext('No recorded matches found.'))
	end

	Array.forEach(self.matches, function (match)
		Array.forEach(match.games, function (game)
			displayTable:node(self:buildRow(match, game))
		end)
	end)

	return mw.html.create('div')
		:addClass('table-responsive')
		:node(displayTable)
end

return ChampionMatchTable
