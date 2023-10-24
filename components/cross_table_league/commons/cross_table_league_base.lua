---
-- @Liquipedia
-- wiki=commons
-- page=Module:CrossTableLeague/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Team = require('Module:Team')

local TournamentStructure = Lua.import('Module:TournamentStructure', {requireDevIfEnabled = true})

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local SCORE_STATUS = 'S'
local DEFAULT_WIN = 'W'

---@class CrossTableLeague
---@operator call(table?): CrossTableLeague
---@field args table
---@field config CrossTableLeagueConfig
---@field opponents {[1]: CrossTableLeagueEntry[]?, [2]: CrossTableLeagueEntry[]?, isMirrored: boolean}
---@field matches table[][]?
---@field display Html
local CrossTableLeague = Class.new()

---@class CrossTableLeagueEntry
---@field opponent standardOpponent
---@field aliases string[]

---@class CrossTableLeagueConfig
---@field startDate number?
---@field endDate number?
---@field isSingle boolean
---@field walkoverWin number
---@field cellwidth number
---@field matchGroupSpecs table
---@field buttonStyle string?
---@field queryOrder string
---@field dateLess boolean
---@field date string

---@param args table?
---@return self
function CrossTableLeague:read(args)
	self.args = args or {}
	self.config = self:readConfig()
	self.opponents = self:readOpponents()

	return self
end

---@return CrossTableLeagueConfig
function CrossTableLeague:readConfig()
	local args = self.args

	return {
		startDate = DateExt.readTimestampOrNil(args.sdate),
		endDate = DateExt.readTimestampOrNil(args.edate),
		isSingle = Logic.readBool(args.single),
		walkoverWin = tonumber(args.walkover_win) or 0,
		cellwidth = (tonumber(args.cellwidth) or 60),
		matchGroupSpecs = TournamentStructure.readMatchGroupsSpec(args) or TournamentStructure.currentPageSpec(),
		buttonStyle = args.button,
		queryOrder = Logic.readBool(args.backwards) and 'date desc' or 'date asc',
		dateLess = Logic.readBool(args.dateless),
		date = DateExt.getContextualDateOrNow(),
	}
end

---@return {[1]: CrossTableLeagueEntry[]?, [2]: CrossTableLeagueEntry[]?, isMirrored: boolean}
function CrossTableLeague:readOpponents()
	local args = self.args

	local leftSide = self:_readSideOpponents(args.opponent1 and 'opponent'
		or args.team1 and 'team'
		or args.player1 and 'player' or nil)

	if not leftSide then return {} end

	local bottomSide = self:_readSideOpponents(args.bopponent1 and 'opponent'
		or args.bteam1 and 'team'
		or args.bplayer1 and 'player' or nil, 'b')

	return {leftSide, bottomSide or leftSide, isMirrored = not bottomSide}
end

---@param keyPrefix string?
---@param side string?
---@return CrossTableLeagueEntry[]?
function CrossTableLeague:_readSideOpponents(keyPrefix, side)
	if not keyPrefix then return end
	local args = self.args
	side = side or ''

	local entries = {}
	for prefix, opponentInput in Table.iter.pairsByPrefix(args, side .. keyPrefix) do
		local opponent
		if keyPrefix == 'opponent' then
			opponent = Json.parseIfTable(opponentInput)
		elseif keyPrefix == Opponent.team then
			opponent = {type = Opponent.team, template = opponentInput}
		else --player case
			opponent = {type = Opponent.solo, players = {{
				name = opponentInput,
				flag = args[prefix .. 'flag'],
				link = args[prefix .. 'link'],
			}}}
		end
		opponent = Opponent.resolve(Opponent.readOpponentArgs(opponent), self.config.date, {syncPlayer = true})
		opponent.name = opponent.name or Opponent.toName(opponent)
		table.insert(entries, {
			opponent = opponent,
			aliases = self:_processAliases(opponent.type, args[prefix .. 'alias'], opponentInput)
		})
	end

	return entries
end

---@param opponentType string
---@param aliasInput string?
---@param opponentInput string
---@return string[]
function CrossTableLeague:_processAliases(opponentType, aliasInput, opponentInput)
	if not aliasInput then return {} end
	local aliases = mw.text.split(aliasInput, ',')

	if opponentType ~= Opponent.team then
		return aliases
	end

	aliases = Array.map(aliases, function(alias) return Team.page(nil, alias, self.config.date) end)

	local allAliases = {}
	Array.forEach(aliases, function(alias)
		Array.extendWith(allAliases, {alias}, Team.queryHistoricalNames(alias:gsub('_', ' '):lower()))
	end)
	--for team input the `opponentInput` is supposed to be a team template, query historical names for it as aliases too
	Array.extendWith(allAliases, Team.queryHistoricalNames(opponentInput:gsub('_', ' '):lower()))

	return allAliases
end

---@return self
function CrossTableLeague:query()
	local config = self.config

	local conditions = {TournamentStructure.getMatch2Filter(config.matchGroupSpecs)}

	local toOpponentCondition = function(name)
		return '[[opponent::' .. name .. ']]'
	end

	local opponentConditions = {}
	Array.forEach(self.opponents, function(entries)
		Array.forEach(entries, function(entry)
			table.insert(opponentConditions, toOpponentCondition(entry.opponent.name))
			Array.extend(opponentConditions, Array.map(entry.aliases, toOpponentCondition))
		end)
	end)
	if Table.isNotEmpty(opponentConditions) then
		table.insert(conditions, '(' .. table.concat(opponentConditions, ' OR ') .. ')')
	end

	if config.startDate then
		table.insert(conditions, '([[date::>' .. config.startDate .. ']] OR [[date::' .. config.startDate .. ']])')
	end

	if config.endDate then
		table.insert(conditions, '([[date::<' .. config.endDate .. ']] OR [[date::' .. config.endDate .. ']])')
	end

	if not config.dateLess then
		table.insert(conditions, '([[date::!1970-01-01 00:00:00]] OR [[finished::1]])')
	end

	self.matches = self:_filterAndSortMatches(mw.ext.LiquipediaDB.lpdb('match2', {
		limit = 1000,
		offset = 0,
		order = config.queryOrder,
		conditions = table.concat(conditions, ' AND '),
	}))

	return self
end

---@param match table
---@return table
function CrossTableLeague._flipMatch(match)
	local copy = Table.deepCopy(match)
	--switch opponents; scores are inside opponents and switch too
	copy.match2opponents[1] = match.match2opponents[2]
	copy.match2opponents[2] = match.match2opponents[1]

	return copy
end

---@param matches table[]
---@return table[][]?
function CrossTableLeague:_filterAndSortMatches(matches)
	if not matches[1] then return end

	if not self.opponents[1] then
		self.opponents = self:_readOpponentsFromMatches(matches)
	end

	local foundMatches = Array.map(self.opponents[1], function() return {} end)

	-- helper table to be able to build local recursive function
	local p = {}
	p.processMatch = function(match, hasBeenProcessed)
		local opponents = match.match2opponents
		local leftIndex = self:_findEntryIndex(self.opponents[1], opponents[1].name)
		local rightIndex = self:_findEntryIndex(self.opponents[2], opponents[2].name)

		if hasBeenProcessed and (not leftIndex or not rightIndex) then
			return
		elseif not leftIndex or not rightIndex then
			return p.processMatch(CrossTableLeague._flipMatch(match), true)
		end
		---@cast rightIndex -nil

		if foundMatches[leftIndex][rightIndex] and hasBeenProcessed then
			return
		elseif foundMatches[leftIndex][rightIndex] then
			return p.processMatch(CrossTableLeague._flipMatch(match), true)
		end

		foundMatches[leftIndex][rightIndex] = match

		if self.config.isSingle and self.opponents.isMirrored then
			foundMatches[rightIndex][leftIndex] = CrossTableLeague._flipMatch(match)
		elseif self.config.isSingle then
			return p.processMatch(CrossTableLeague._flipMatch(match), true)
		end
	end

	for _, match in pairs(matches) do
		p.processMatch(match)
	end

	return foundMatches
end

---@param entries CrossTableLeagueEntry
---@param name string
---@return integer?
function CrossTableLeague:_findEntryIndex(entries, name)
	for entryIndex, entry in ipairs(entries) do
		if name == entry.opponent.name or Table.includes(entry.aliases, name) then
			return entryIndex
		end
	end
end

---@param matches table[]
---@return {[1]: CrossTableLeagueEntry[]?, [2]: CrossTableLeagueEntry[]?, isMirrored: boolean}
function CrossTableLeague:_readOpponentsFromMatches(matches)
	local aliases = {}
	local entries = {}

	local processOpponent = function(opponentRecord)
		local opponent = Opponent.fromMatch2Record(opponentRecord)
		opponent.name = opponent.name or opponentRecord.name

		if Opponent.isEmpty(opponent) or Opponent.isTbd(opponent) or aliases[opponent.name] then return end

		local entry = {
			opponent = opponent,
			aliases = opponent.type == Opponent.team and Team.queryHistoricalNames(opponent.name) or {},
		}

		table.insert(entries, entry)
		aliases[opponent.name] = true
		for _, alias in pairs(entry.aliases) do
			aliases[alias] = true
		end
	end

	for _, match in pairs(matches) do
		processOpponent(match.match2opponents[1])
		processOpponent(match.match2opponents[2])
	end

	Array.sortInPlaceBy(entries, function(entry) return entry.opponent.name end)

	return {entries, entries, isMirrored = true}
end

---@return Html?
function CrossTableLeague:create()
	if not self.matches and not self.opponents[1] then
		return
	elseif not self.matches then
		self.matches = Array.map(self.opponents[1], function()
			return Array.map(self.opponents[2], function() return {} end) end)
	end

	self.display = mw.html.create('div')
		:addClass('table-responsive toggle-area toggle-area-1')
		:attr('data-toggle-area', '1')

	self:_button()

	local tableWidth = #self.opponents[2] * self.config.cellwidth + 26
	if self.config.buttonStyle ~= 'above' or not self.config.isSingle then
		tableWidth = tableWidth + self.config.cellwidth
	end

	local tableDisplay = self.display:tag('div')
		:css('min-width',tableWidth .. 'px')

	if self.config.buttonStyle ~= 'above' then
		tableDisplay:css('float', 'left')
	end

	self.table = tableDisplay:tag('table')
		:addClass('wikitable wikitable-bordered crosstable')
		:css('margin', '0px 13px 13px 0px')

	Array.forEach(self.opponents[1], function(entry, rowIndex)
		local row = self.table:tag('tr'):addClass('crosstable-tr')
			:tag('th'):node(OpponentDisplay.BlockOpponent{
				opponent = entry.opponent,
				teamStyle = 'icon',
			}):done()
		for columnIndex in ipairs(self.opponents[2]) do
			row:node(self:displayCell(rowIndex, columnIndex))
		end
		if self.opponents.isMirrored and not self.config.isSingle then
			self:addTotalCells(row, rowIndex)
		end
		if rowIndex == 1 and self.config.isSingle then
			row:attr('data-toggle-area-content', '2')
		end
	end)

	local bottomRow = self.table:tag('tr'):addClass('crosstable-tr'):tag('th'):done()

	local toggleGroup
	local bottomCell = function(entry, columnIndex)
		local cell = bottomRow:tag('th')
			:node(OpponentDisplay.BlockOpponent{
				opponent = entry.opponent,
				teamStyle = 'icon',
			})
		if toggleGroup or columnIndex == #self.opponents[2] and self.config.isSingle then
			cell:attr('data-toggle-area-content', toggleGroup or '2')
		end
	end

	if self.opponents.isMirrored and not self.config.isSingle then
		toggleGroup = '1'
	end
	Array.forEach(self.opponents[2], bottomCell)

	if self.opponents.isMirrored and not self.config.isSingle then
		toggleGroup = '2'
		Array.forEach(self.opponents[2], bottomCell)
	end

	return self.display
end

---@return Html?
function CrossTableLeague:_button()
	if self.config.buttonStyle == 'hidden' or not self.opponents.isMirrored then
		return
	end

	local openText, closeText = 'Show Aggregate', 'Show Individual'
	if self.config.isSingle then
		openText, closeText = 'Show Duplicates', 'Hide Duplicates'
	end

	local buildButton = function(text, toggleGroup)
		self.display:tag('span')
			:attr('data-toggle-area-content', tostring(toggleGroup))
			:tag('span')
				:addClass('toggle-area-button btn btn-primary')
				:attr('data-toggle-area-btn', tostring(3 - toggleGroup))
				:css('width', '150px')
				:css('margin-bottom', '12px')
				:wikitext(text)
				:done()
			:done()
	end

	buildButton(openText, 1)
	buildButton(closeText, 2)
end

---@param rowIndex integer
---@param columnIndex integer
---@param toggleArea string?
---@return Html
function CrossTableLeague:displayCell(rowIndex, columnIndex, toggleArea)
	local cell = mw.html.create('td')
	local match = self.matches[rowIndex][columnIndex]
	toggleArea = toggleArea
		or self.config.isSingle and rowIndex <= columnIndex and '2'
		or self.opponents.isMirrored and not self.config.isSingle and '1'
		or nil

	if not match and rowIndex == columnIndex and self.opponents.isMirrored then
		return cell
			:addClass('crosstable-bgc-cross')
			:attr('data-toggle-area-content', toggleArea)
			:css('min-width', self.config.cellwidth .. 'px')
	elseif not match then
		return cell
			:addClass('crosstable-bgc-r-r')
			:attr('data-toggle-area-content', toggleArea)
			:css('min-width', self.config.cellwidth .. 'px')
	end

	local body = mw.html.create('b')
	local opponents = match.match2opponents or {{}, {}}
	local scores = {
		CrossTableLeague._getScore(opponents[1]),
		CrossTableLeague._getScore(opponents[2]),
	}
	if Logic.readBool(match.finished) or self.config.dateLess then
		body:wikitext(scores[1] .. ':' .. scores[2])
	else
		body:wikitext('&nbsp;')
	end

	return cell
		:addClass('crosstable-bgc-r' .. scores[1] .. '-r' .. scores[2] .. (match.winner == 0 and '-draw' or ''))
		:css('min-width', self.config.cellwidth .. 'px')
		:attr('data-toggle-area-content', toggleArea)
		:node(body)
		:node(CrossTableLeague.footer(match))
end

---@param opponent standardOpponent
---@return string|number|nil
function CrossTableLeague._getScore(opponent)
	return opponent.status ~= SCORE_STATUS and opponent.status or
		opponent.score ~= -1 and opponent.score or 0
end

---@param match table
---@return Html?
function CrossTableLeague.footer(match)
	local timestamp = DateExt.readTimestampOrNil(match.date) or 0
	if not Logic.readBool(match.dateexact) and timestamp == 0 then
		return
	end

	return mw.html.create()
		:wikitext('<br>')
		:tag('span')
			:css('font-size', '80%')
			:wikitext(DateExt.formatTimestamp('M j', timestamp))
			:done()
end

function CrossTableLeague:addTotalCells(row, rowIndex)
	for columnIndex in ipairs(self.opponents[2]) do
		row:node(self:displayTotalCell(rowIndex, columnIndex))
	end
end

---@param rowIndex integer
---@param columnIndex integer
---@return Html
function CrossTableLeague:displayTotalCell(rowIndex, columnIndex)
	local match = self.matches[rowIndex][columnIndex]
	if not match then
		return mw.html.create('td')
			:addClass('crosstable-bgc-cross')
			:attr('data-toggle-area-content', '2')
			:css('min-width', self.config.cellwidth .. 'px')
	end

	local opponents = (match or {}).match2opponents or {{}, {}}
	local scores1 = {
		CrossTableLeague._getScore(opponents[1]),
		CrossTableLeague._getScore(opponents[2]),
	}

	local mirrorColumnIndex = self:_findEntryIndex(self.opponents[2], opponents[2].name)
	local mirrorRowIndex = self:_findEntryIndex(self.opponents[1], opponents[1].name)

	local mirroredMatch = (self.matches[mirrorRowIndex] or {})[mirrorColumnIndex]

	if not mirroredMatch then
		return self:displayCell(rowIndex, columnIndex, '2')
	end

	local mirroredMatchOpponents = mirroredMatch.match2opponents or {{}, {}}
	local scores2 = {
		CrossTableLeague._getScore(mirroredMatchOpponents[1]),
		CrossTableLeague._getScore(mirroredMatchOpponents[2]),
	}

	local toSumScore = function(scoreValue)
		return tonumber(scoreValue) or scoreValue == DEFAULT_WIN and self.config.walkoverWin or 0
	end

	local totalScores = {
		toSumScore(scores1[1]) + toSumScore(scores2[1]),
		toSumScore(scores1[2]) + toSumScore(scores2[2]),
	}

	local footer = mw.html.create()
		:wikitext('<br>')
		:tag('span')
			:css('font-size', '80%')
			:wikitext(table.concat(scores1, ':') .. ', ' .. table.concat(scores2, ':'))
			:done()

	return mw.html.create('td')
		:addClass('crosstable-bgc-r' .. totalScores[1] .. '-r' .. totalScores[2])
		:css('min-width', self.config.cellwidth .. 'px')
		:attr('data-toggle-area-content', '2')
		:node(table.concat(totalScores, ':'))
		:node(footer)
end

return CrossTableLeague
