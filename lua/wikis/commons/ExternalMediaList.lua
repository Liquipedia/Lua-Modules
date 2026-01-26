---
-- @Liquipedia
-- page=Module:ExternalMediaList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')

local ExternalMediaFormLink = Lua.import('Module:Widget/ExternalMedia/FormLink')
local ExternalMediaListDisplay = Lua.import('Module:Widget/ExternalMedia/List')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local MediaList = {}

---Main function for ExternalMediaList.
---Queries External Media Links for the given conditions (via arguments).
---Calls the display functions based on setting (supplied in arguments).
---@param args table
---@return Html?
function MediaList.get(args)
	args = MediaList._parseArgs(args)

	local data = mw.ext.LiquipediaDB.lpdb('externalmedialink', {
		conditions = tostring(MediaList._buildConditions(args)),
		order = 'date desc',
		limit = args.limit
	})

	--if we do not get any results from the query return empty string
	if type(data[1]) ~= 'table' then return end

	---@return string|Widget|Widget[]|Html?
	local function createDisplay()
		if args.separateByYears and args.dynamic and not args.year then
			return MediaList._displayDynamic(data, args)
		elseif args.separateByYears and not args.year then
			return MediaList._displayByYear(data, args)
		end
		return MediaList._displayYear(data, args)
	end

	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		createDisplay(),
		MediaList._formLink(args.linkToForm)
	)}
end

---Parses the arguments for further usage in this module.
---@param args table
---@return table
function MediaList._parseArgs(args)
	args = args or {}

	args.subject1 = args.subject1 or args.subject
	args.player1 = args.player1 or args.player

	local subjects = Array.mapIndexes(function(subjectIndex)
		local subject = args['subject' .. subjectIndex] or args['player' .. subjectIndex]
		return subject and mw.ext.TeamLiquidIntegration.resolve_redirect(subject) or nil
	end)

	return {
		types = args.type and Array.map(Array.parseCommaSeparatedString(args.type), string.lower) or nil,
		author = args.author and mw.ext.TeamLiquidIntegration.resolve_redirect(args.author) or nil,
		subjects = subjects,
		org = args.organization and mw.ext.TeamLiquidIntegration.resolve_redirect(args.organization) or nil,
		showUsUk = Logic.readBool(args.show_usuk),
		year = tonumber(args.year),
		limit = tonumber(args.limit) or 100,
		separateByYears = Logic.readBool(args.seperate_years or args.separate_years),
		dynamic = Logic.emptyOr(Logic.readBoolOrNil(args.dynamic), true),
		linkToForm = Logic.readBool(args.linkToForm),
		booleanOperator = Logic.readBool(args['and']) and BooleanOperator.all or BooleanOperator.any,
		isEventPage = Logic.readBool(args.event),
		event = Logic.readBool(args.event)
			and mw.title.getCurrentTitle().prefixedText
			or (args.event and mw.ext.TeamLiquidIntegration.resolve_redirect(args.event))
			or nil,
		showSubjectTeam = Logic.readBool(args.showSubjectTeam) and #subjects == 1
	}
end

---Builds the query conditions for the given arguments
---@param args table
---@return ConditionTree
function MediaList._buildConditions(args)
	local conditions = ConditionTree(BooleanOperator.all):add(
		ConditionNode(ColumnName('namespace'), Comparator.eq, 136)
	)

	if Table.isNotEmpty(args.types) then
		conditions:add(ConditionUtil.anyOf(ColumnName('type'), args.types))
	end

	if args.year then
		conditions:add(ConditionNode(ColumnName('year', 'date'), Comparator.eq, args.year))
	end

	local additionalConditions = ConditionTree(args.booleanOperator)

	additionalConditions:add(Array.map(args.subjects, function (subject)
		return MediaList._buildMultiKeyCondition(subject, 'extradata_subject', 20)
	end))

	if args.org then
		additionalConditions:add{
			ConditionUtil.anyOf(ColumnName('extradata_subject_organization'), {args.org, args.org:gsub(' ', '_')}),
			MediaList._buildMultiKeyCondition(args.org, 'extradata_subject_organization', 5)
		}
	end

	additionalConditions:add(MediaList._buildMultiKeyCondition(args.author, 'authors_author', 5))

	if args.event then
		additionalConditions:add(
			ConditionUtil.anyOf(ColumnName('extradata_event_link'), {args.event, args.event:gsub(' ', '_')})
		)
	end

	conditions:add(additionalConditions)

	return conditions
end

---Builds a multi key condition for a given prefix and value
---@param value string|number
---@param prefix string
---@param limit integer
---@return ConditionTree?
function MediaList._buildMultiKeyCondition(value, prefix, limit)
	if Logic.isEmpty(value) then
		return
	end
	return ConditionTree(BooleanOperator.any):add(
		Array.map(Array.range(1, limit), function (index)
			return ConditionUtil.anyOf(ColumnName(prefix .. index), {value, value:gsub(' ', '_')})
		end)
	)
end

---Builds the display for the dynamic tabs per year option
---@param data externalmedialink[]
---@param args table
---@return Html|string?
function MediaList._displayDynamic(data, args)
	local tabsData = {}

	local tabIndex = 1
	for year, yearItems in Table.iter.spairs(MediaList._groupByYear(data), MediaList._sortInYear) do
		tabsData['name' .. tabIndex] = year
		tabsData['content' .. tabIndex] = MediaList._displayYear(yearItems, args)

		tabIndex = tabIndex + 1
	end

	return Tabs.dynamic(tabsData)
end

---Builds the display for the per year option (without tabs)
---@param data externalmedialink[]
---@param args table
---@return Widget[]
function MediaList._displayByYear(data, args)
	local display = {}

	for year, yearItems in Table.iter.spairs(MediaList._groupByYear(data), MediaList._sortInYear) do
		Array.appendWith(display, HtmlWidgets.H4{children = year}, MediaList._displayYear(yearItems, args))
	end

	return display
end

---Groups provided data by year
---@param data externalmedialink[]
---@return table<string, externalmedialink[]>
function MediaList._groupByYear(data)
	local _, groupedData = Array.groupBy(data, function(item)
		return item.date:sub(1, 4)
	end)

	return groupedData
end

---Sort function to sort External Media Links within a year
---@param _ string[]?
---@param key1 string
---@param key2 string
---@return boolean
function MediaList._sortInYear(_, key1, key2)
	return key1 > key2
end

---Displays the External Media Links for a given data set (usually of a year)
---@param data externalmedialink[]
---@param args table
---@return Widget
function MediaList._displayYear(data, args)
	return ExternalMediaListDisplay{
		data = data,
		subject = args.subjects[1],
		showSubjectTeam = args.showSubjectTeam,
		showUsUk = args.showUsUk,
	}
end

---Displays the link to the Form with which External Media Links are to be created.
---@param show boolean defines if the link is to be displayed or not
---@return Widget?
function MediaList._formLink(show)
	if not show then return end

	return ExternalMediaFormLink()
end

return Class.export(MediaList, {exports = {'get'}})
