---
-- @Liquipedia
-- page=Module:NextMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local NextMatch = {}

---@param frame Frame
---@return string|Html
function NextMatch.run(frame)
	local args = Arguments.getArgs(frame)

	if not args[1] then return args.default or '' end

	local pageConditions = ConditionTree(BooleanOperator.any)
	for _, page in ipairs(args) do
		local title = mw.title.new(page)
		assert(title, 'Invalid pagename "' .. page .. '"')
		local namespace, basePage, stage = Logic.nilIfEmpty(title.nsText), title.text, Logic.nilIfEmpty(title.fragment)
		basePage = basePage:gsub(' ', '_')
		pageConditions:add(ConditionTree(BooleanOperator.all):add(Array.append(
			{ConditionNode(ColumnName('pagename'), Comparator.eq, basePage)},
			namespace and ConditionNode(ColumnName('namespace'), Comparator.eq, Namespace.idFromName(namespace)) or nil,
			stage and ConditionNode(ColumnName('sectionheader', 'match2bracketdata'), Comparator.eq, stage) or nil
		)))
	end

	local now = DateExt.getCurrentTimestamp()
	local yesterday = now - 24 * 3600

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('finished'), Comparator.eq, 0),
		ConditionNode(ColumnName('date'), Comparator.ge, yesterday),
		pageConditions
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

	-- fallback for wikis still not having match2 (e.g. formula1)
	if Logic.isEmpty(match) and Info.config.match2.status == 0 then
		match = mw.ext.LiquipediaDB.lpdb('match', {
			conditions = tostring(conditions),
			query = 'date, stream',
			order = 'date asc',
			limit = 1,
		})[1] or {}
	end

	if not match.date then return args.default or '' end

	local countdownArgs = {}
	if Logic.readBool(args.showStreams) then
		countdownArgs = match.stream or {}
	end
	Table.mergeInto(countdownArgs, args)
	countdownArgs.date = DateExt.toCountdownArg(match.date, (match.extradata or {}).timezoneid)
	countdownArgs.rawcountdown = true

	if Logic.readBool(args.matchWrapper) then
		return mw.html.create('span')
			:addClass('match-countdown')
			:wikitext(Countdown.create(countdownArgs))
	end

	return Countdown.create(countdownArgs)
end

return NextMatch
