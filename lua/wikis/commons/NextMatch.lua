---
-- @Liquipedia
-- page=Module:NextMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local NextMatch = {}

---@param args table
---@return string|Widget
function NextMatch.run(args)
	if not args[1] then return args.default or '' end

	local matchGroupsSpec = TournamentStructure.readMatchGroupsSpec(
		Table.map(
			Table.filterByKey(args, function (key)
				return MathUtil.isInteger(key) or String.startsWith(key, 'tournament')
			end),
			function (key, value)
				if String.startsWith(key, 'tournament') then
					return key, value
				end
				return 'tournament' .. key, value
			end
		)
	)

	if not matchGroupsSpec then
		return ''
	end

	local now = DateExt.getCurrentTimestamp()
	local yesterday = now - DateExt.daysToSeconds(1)

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('finished'), Comparator.eq, 0),
		ConditionNode(ColumnName('date'), Comparator.ge, yesterday),
		TournamentStructure.getMatch2Filter(matchGroupsSpec)
	}

	if not Logic.readBool(args.notExact) then
		conditions:add(ConditionNode(ColumnName('dateexact'), Comparator.eq, 1))
	end

	local match = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(conditions),
		query = 'date, stream, extradata',
		order = 'date asc',
		limit = 1,
	})[1] or {}

	if not match.date then return args.default or '' end

	local countdownArgs = {}
	if Logic.readBool(args.showStreams) then
		countdownArgs = match.stream or {}
	end
	Table.mergeInto(countdownArgs, args)
	countdownArgs.date = DateExt.toCountdownArg(match.date, (match.extradata or {}).timezoneid)
	countdownArgs.rawcountdown = true

	if Logic.readBool(args.matchWrapper) then
		return HtmlWidgets.Span{
			classes = {'match-countdown'},
			children = Countdown.create(countdownArgs)
		}
	end

	return Countdown.create(countdownArgs)
end

return Class.export(NextMatch, {exports = {'run'}})
