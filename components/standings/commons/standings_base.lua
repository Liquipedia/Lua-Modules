---@diagnostic disable: duplicate-set-field, duplicate-doc-field
---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--


--- this module together with /Custom adjusts, /Input and /Import is basically step 3 of the RFC


local Array = require('Module:Array')
local Box = require('Module:Box')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')

local Storage = Lua.import('Module:Standings/Storage')

---@class standardStanding
---@field type standingType
---@field matches string[]
---@field entries standardStandingEntry
---@field entryIndexesByName table<string, integer>
---@field matchRecordsByRound match2[][]
---@field matchResultsByRound table<integer, standingMatchEntryResult>[][]
---@field resultsByRound standingResult[][]
---@field rounds {range: {[1]: integer, [2]: integer}, startIsExact: boolean, title: string}[]
---@field structure standingStructure
---@field slots {pbg: string}
---@field status standingStatus
---@field results standingResult[]
---@field options {hasPoints: boolean, resolveDate: string?, streams: table, title: string?} #formerly "tableProps"

---@class standingStructure
---@field type 'gsl'|'roundRobin'|'swiss'|'other'
---@field cycleCount integer? # only for roundRobin
---@field roundCount integer? # only for swiss

---@class standingStatus
---@field currentRoundIndex number
---@field groupFinished boolean
---@field groupStarted boolean
---@field roundFinished boolean
---@field roundIsLive boolean
---@field roundStarted boolean

---@class standingResult
---@field bg string?
---@field pbg string?
---@field dq boolean?
---@field finalTiebreak number
---@field placeRange {[1]: integer, [2]: integer} #start, end
---@field placeRangeIsExact boolean
---@field rank integer
---@field slotIndex integer
---@field rankChange integer?
---@field gameScore scoreInfo
---@field matchScore scoreInfo
---@field points integer
---later: add overtime stuff here!

---@class standingMatchEntryResult
---@field gameScore scoreInfo
---@field matchScore scoreInfo
---@field points integer
---later: add overtime stuff here!

---@class standardStandingEntry
---@field opponent standardOpponent
---@field aliases string[]
---@field identifierKey 'name'|'template' #template for team opponents, name for other opponents
---@field note string?

---@class BaseStandings
---@field args table
---@field config table
---@field group standardStanding
local BaseStandings = Class.new(function(self, args)
	self.args = args
end)

BaseStandings.LINKS_DATA = {}

BaseStandings.Dispaly = Lua.import('Module:Standings/Display') -- todo
BaseStandings.Input = Lua.import('Module:Standings/Input') -- todo
BaseStandings.Import = Lua.import('Module:Standings/Import') -- todo / possibly gets renamed!

---@param args table
---@return Html
function BaseStandings.displayStandingFromLpdb(args)
	assert(args and args.pagename, 'No pagename specified')
	assert(args and Logic.isNumeric(args.standings_index), 'No standings_index specified')

	local conditions = Array.extend(
		args.namespace and ('[[namespace::' .. args.namespace .. ']]') or nil,
		'[[pagename::' .. args.pagename:gsub('%s', '_') .. ']]',
		'[[standingsindex::' .. args.standings_index .. ']]'
	)

	local groups = BaseStandings._query(conditions)

	return BaseStandings._displayGroups(groups)
end

---@param args table
---@return Html
function BaseStandings.displayStageStandingsFromLpdb(args)
	assert(args and args.stage, 'No stage specified')

	local title = mw.title.new(args.stage)
	assert(title, 'Invalid stage specified')

	local namespaceName = Logic.nilIfEmpty(title.nsText)
	local basePageName = title.text
	local stageName = Logic.nilIfEmpty(title.fragment)

	local conditions = Array.extend(
		namespaceName and ('[[namespace::' .. Namespace.idFromName(namespaceName) .. ']]') or nil,
		('[[pagename::' .. basePageName:gsub('%s', '_') .. ']]'),
		stageName and ('[[extradata_stagename::' .. stageName .. ']]') or nil
	)

	local groups = BaseStandings._query(conditions)

	return BaseStandings._displayGroups(groups)
end

---@param conditions string[]
---@return standardStanding[]
function BaseStandings._query(conditions)
	local groupRecords = mw.ext.LiquipediaB.lpdb('standingstable', {
		conditions = table.concat(conditions, ' AND '),
		limit = 5000,
	})

	assert(type(groupRecords[1] == 'table'), 'No results found')

	groupRecords = Array.map(groupRecords, BaseStandings._fetchEntries)

	local groups = Array.map(groupRecords, Storage.fromStorageStruct)

	Array.map(groups, BaseStandings._backFillVs)

	return groups
end

---@param group standingStorageStruct
---@return standingStorageStruct
function BaseStandings._fetchEntries(group)
	local conditions = Array.extend(
		'[[namespace::' .. group.namespace .. ']]',
		'[[pagename::' .. group.pagename .. ']]',
		'[[standingsindex::' .. group.standingsindex .. ']]'
	)

	group.entries = mw.ext.LiquipediaDB.lpdb('standingsentry', {
		conditions = table.concat(conditions, ' AND '),
		limit = '100',
	})

	return group
end

---@param groups standingStorageStruct
---@return Html
function BaseStandings._displayGroups(groups)

	local numberOfGroups = Table.size(groups)

	if numberOfGroups == 1 then
		return BaseStandings.Dispaly(groups[1]):build()
	end

	local display = mw.html.create()
		:node(Box.start{padding = '2em'})

	Array.forEach(groups, function(group, groupIndex)
		display
			:node(BaseStandings.Dispaly(group):build())
			:node(groupIndex ~= numberOfGroups and Box.brk{padding = '2em'} or nil)
	end)

	return display:node(Box.finish())
end

--- fill in vs data per entry (per round) for swiss tables
---@param group standardStanding
---@return standardStanding
function BaseStandings._backFillVs(group)
	if group.type ~= Storage.STANDING_TYPES.SWISS then
		return group
	end

	local matchConditions = Array.map(group.matches, function(matchId)
		return '[[match2id::' .. matchId .. ']]'
	end)

	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = table.concat(matchConditions, ' OR '),
		query = 'match2opponents, extradata, ',
		limit = '5000',
	})

	-- todo: sort the matches towards the correct entries
	-- todo: extract vs information from the matches for the according entries
end

---@param defaultTieBreakers string[]
---@return self
function BaseStandings:setDefaultTieBreakers(defaultTieBreakers)
	if Logic.isNotEmpty(defaultTieBreakers) then
		self.defaultTieBreakers = defaultTieBreakers
	end
	return self
end

---@return self
function BaseStandings:read()
	self.config = BaseStandings.Input.readConfig(self.args)
	self.group = BaseStandings.Input.readGroup(self.args)

	return self
end

---@return self
function BaseStandings:process()
	self.group = BaseStandings.Import(self):query():process()

	return self
end

---@return self
function BaseStandings:store()
	if Logic.readBoolOrNil(self.args.storeStanding) == false then
		return self
	end

	local storageData = Storage.toStorageData(self.group)
	Storage.run(storageData)

	return self
end

---@return Html
function BaseStandings:build()
	return BaseStandings.Dispaly(self.group):build()
end

return BaseStandings
