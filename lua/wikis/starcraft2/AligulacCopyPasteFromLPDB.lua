---
-- @Liquipedia
-- page=Module:AligulacCopyPasteFromLPDB
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local I18n = Lua.import('Module:I18n')
local Logic = Lua.import('Module:Logic')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')
local WidgetUtil = Lua.import('Module:Widget/Util')

local AligulacCopyPasteFromLPDB = {}

---@param frame Frame
---@return VNode
function AligulacCopyPasteFromLPDB.run(frame)
	local conditions, spec = AligulacCopyPasteFromLPDB._buildConditions(frame)
	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		limit = 5000,
		order = 'match2id asc',
		conditions = conditions,
	})

	local parts = {}
	Array.forEach(matches, function(match)
		Array.extendWith(parts,
			AligulacCopyPasteFromLPDB._getHeader(match),
			AligulacCopyPasteFromLPDB._match(match)
		)
	end)

	return Html.Fragment{
		children = WidgetUtil.collect(
			AligulacCopyPasteFromLPDB._queriedFrom(spec),
			Html.Pre{
				classes = {'selectall'},
				children = Array.interleave(parts, '\n'),
			}
		),
	}
end

---@param frame Frame
---@return string
---@return MatchGroupsSpec
function AligulacCopyPasteFromLPDB._buildConditions(frame)
	local args = Arguments.getArgs(frame)

	local ids = Array.parseCommaSeparatedString(args.ids)
	local specArgs = Table.map(ids, function(index, value)
		return 'matchGroupId' .. index, value
	end)

	local stages = Array.parseCommaSeparatedString(args.stages)
	local parents = Array.parseCommaSeparatedString(args.parents)
	Array.forEach(parents, function(parent)
		Array.extendWith(stages, AligulacCopyPasteFromLPDB._pagesOfParent(parent))
	end)
	stages = Array.unique(stages)

	Table.mergeInto(specArgs, Table.map(stages, function(index, value)
		return 'tournament' .. index, value
	end))

	local matchGroupsSpec = TournamentStructure.readMatchGroupsSpec(specArgs)
	assert(matchGroupsSpec, 'Missing inputs')

	return tostring(TournamentStructure.getMatch2Filter(matchGroupsSpec)), matchGroupsSpec
end

---@param parent string
---@return string[]
function AligulacCopyPasteFromLPDB._pagesOfParent(parent)
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(ConditionNode(ColumnName('parent'), Comparator.eq, parent)),
		limit = 100,
		query = 'pagename',
		groupby = 'pagename asc',
	})
	local pages = Array.map(data, Operator.property('pagename'))
	return Array.appendWith(pages, parent)
end

---@param match match2
---@return string?
function AligulacCopyPasteFromLPDB._getHeader(match)
	---@param header string
	---@return string
	local makeHeader = function(header)
		return '\n***** ' .. header .. ' *****'
	end

	if match.match2bracketdata.type == 'matchlist' then
		local matchnumber = string.gsub(match.match2id, match.match2bracketid .. '_', '')
		if matchnumber ~= '0001' then
			return
		end
		local title = Logic.nilIfEmpty(match.match2bracketdata.title) or 'Match List'
		return makeHeader(title)
	end

	local header = match.match2bracketdata.header
	if Logic.isEmpty(header) then
		return
	end

	local headerCodeArray = Array.parseCommaSeparatedString(string.gsub(header, '$', '!'), '!')
	local index = Logic.isEmpty(headerCodeArray[1]) and 2 or 1

	local headerMessage = I18n.translate('brkts-header-' .. headerCodeArray[index], {round = headerCodeArray[index + 1]})
	local headerDisplay = Array.parseCommaSeparatedString(headerMessage, ',')[1]
	if string.match(headerDisplay, 'brkts') then
		headerDisplay = header
	end

	return makeHeader(headerDisplay)
end

---@param spec MatchGroupsSpec
---@return Renderable[]
function AligulacCopyPasteFromLPDB._queriedFrom(spec)
	---@param id string
	---@return string
	local elementId = function(id)
		return id .. ' (matchGroupId)'
	end

	---@param page string
	---@return string
	local elementPage = function(page)
		return Html.Span{
			children = {
				Link{link = page},
				' (page/stage)',
			},
		}
	end

	return {
		Html.B{children = 'Data retrieved from:'},
		UnorderedList{
			children = WidgetUtil.collect(
				Array.map(spec.matchGroupIds, elementId),
				Array.map(spec.pageNames, elementPage)
			),
		},
		Html.Br{},
	}
end

---@param record match2
---@return string[]?
function AligulacCopyPasteFromLPDB._match(record)
	if Table.size(record.match2opponents) ~= 2 then
		return
	end

	local match = MatchGroupUtil.matchFromRecord(record)

	return Array.map(match.submatches or {match}, AligulacCopyPasteFromLPDB._subMatch)
end

---@param match StarcraftMatchGroupUtilSubmatch|MatchGroupUtilMatch
---@return string?
function AligulacCopyPasteFromLPDB._subMatch(match)
	-- remove non score matches (walkovers and the likes)
	if Array.any(match.opponents, function(opponent) return opponent.status ~= 'S' end) then
		return
	end

	-- remove matches with any opponent with more or less than 1 player
	if Array.any(match.opponents, function(opponent) return Table.size(opponent.players) ~= 1 end) then
		return
	end

	local player1 = match.opponents[1].players[1].pageName
	local player2 = match.opponents[2].players[1].pageName
	if Logic.isEmpty(player1) or Logic.isEmpty(player2) then
		return
	end
	---@cast player1 -nil
	---@cast player2 -nil

	return table.concat{
		AligulacCopyPasteFromLPDB._player(player1),
		'-',
		AligulacCopyPasteFromLPDB._player(player2),
		' ',
		match.opponents[1].score,
		'-',
		match.opponents[2].score,
	}
end

---@param player string
---@return string
function AligulacCopyPasteFromLPDB._player(player)
	local data = mw.ext.LiquipediaDB.lpdb('player', {
		limit = 1,
		conditions = tostring(ConditionNode(ColumnName('pagename'), Comparator.eq, player)),
		query = 'id, links'
	})[1] or {}

	return table.concat({
		Logic.nilIfEmpty(data.id) or player:gsub('_', ' '),
		Logic.nilIfEmpty(((data.links or {}).aligulac or ''):gsub('https?://aligulac.com/players/', '')),
	}, ' ')
end

return AligulacCopyPasteFromLPDB
