---
-- @Liquipedia
-- wiki=commons
-- page=Module:ExternalMediaList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Flag = require('Module:Flags')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local PlayerExt = require('Module:Player/Ext/Custom')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tabs = require('Module:Tabs')
local TeamTemplate = require('Module:TeamTemplate')

local TeamIconWidget = Lua.import('Module:Widget/TeamDisplay/Inline/Icon')

local MediaList = {}

local NON_BREAKING_SPACE = '&nbsp;'

---Main function for ExternalMediaList.
---Queries External Media Links for the given conditions (via arguments).
---Calls the display functions based on setting (supplied in arguments).
---@param args table
---@return Html?
function MediaList.get(args)
	args = MediaList._parseArgs(args)

	local data = mw.ext.LiquipediaDB.lpdb('externalmedialink', {
		conditions = MediaList._buildConditions(args),
		order = 'date desc',
		limit = args.limit
	})

	--if we do not get any results from the query return empty string
	if type(data[1]) ~= 'table' then return end

	if args.separateByYears and args.dynamic and not args.year then
		return mw.html.create()
			:node(MediaList._displayDynamic(data, args))
			:node(MediaList._formLink(args.linkToForm))
	elseif args.separateByYears and not args.year then
		return mw.html.create()
			:node(MediaList._displayByYear(data, args))
			:node(MediaList._formLink(args.linkToForm))
	end

	return mw.html.create()
		:node(MediaList._displayYear(data, args))
		:node(MediaList._formLink(args.linkToForm))
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
		types = args.type and Array.map(Array.map(mw.text.split(args.type, ','), String.trim), string.lower) or nil,
		author = args.author and mw.ext.TeamLiquidIntegration.resolve_redirect(args.author) or nil,
		subjects = subjects,
		org = args.organization and mw.ext.TeamLiquidIntegration.resolve_redirect(args.organization) or nil,
		showUsUk = Logic.readBool(args.show_usuk),
		year = tonumber(args.year),
		limit = tonumber(args.limit) or 100,
		separateByYears = Logic.readBool(args.seperate_years or args.separate_years),
		dynamic = Logic.emptyOr(Logic.readBoolOrNil(args.dynamic), true),
		linkToForm = Logic.readBool(args.linkToForm),
		booleanOperator = Logic.readBool(args['and']) and ' AND ' or ' OR ',
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
---@return string
function MediaList._buildConditions(args)
	local conditions = {
		'[[namespace::136]]'
	}

	if Table.isNotEmpty(args.types) then
		table.insert(conditions, '(' .. table.concat(Array.map(args.types, function(typeValue)
			return '[[type::' .. typeValue .. ']]'
		end), ' OR ' ) .. ')')
	end

	if args.year then
		table.insert(conditions, '[[date_year::' .. args.year.. ']]')
	end

	local additionalConditions = {}
	for _, subject in pairs(args.subjects) do
		table.insert(additionalConditions, MediaList._buildMultiKeyCondition(subject, 'extradata_subject', 20))
	end

	if args.org then
		table.insert(
			additionalConditions,
			'([[extradata_subject_organization::'
				.. args.org
				.. ']] OR [[extradata_subject_organization::'
				.. args.org:gsub(' ', '_')
				.. ']])'
		)
		table.insert(additionalConditions, MediaList._buildMultiKeyCondition(args.org, 'extradata_subject_organization', 5))
	end

	if args.author then
		table.insert(additionalConditions, MediaList._buildMultiKeyCondition(args.author, 'authors_author', 5))
	end

	if args.event then
		table.insert(
			additionalConditions,
			'([[extradata_event_link::'
				.. args.event
				.. ']] OR [[extradata_event_link::'
				.. args.event:gsub(' ', '_')
				.. ']])'
		)
	end

	if Logic.isNotEmpty(additionalConditions) then
		table.insert(conditions, '(' .. table.concat(additionalConditions, args.booleanOperator) .. ')')
	end

	return table.concat(conditions, ' AND ')
end

---Builds a multi key condition for a given prefix and value
---@param value string|number
---@param prefix string
---@param limit integer
---@return string
function MediaList._buildMultiKeyCondition(value, prefix, limit)
	return table.concat(Array.map(Array.range(1, limit), function(index)
		return '([[' .. prefix .. index .. '::' .. value .. ']]'
			.. ' OR [['.. prefix .. index .. '::' .. value:gsub(' ', '_') .. ']])'
	end), ' OR ')
end

---Builds the display for the dynamic tabs per year option
---@param data table[]
---@param args table
---@return Html|string?
function MediaList._displayDynamic(data, args)
	local tabsData = {}

	local tabIndex = 1
	for year, yearItems in Table.iter.spairs(MediaList._groupByYear(data), MediaList._sortInYear) do
		tabsData['name' .. tabIndex] = year
		tabsData['content' .. tabIndex] = tostring(MediaList._displayYear(yearItems, args))

		tabIndex = tabIndex + 1
	end

	return Tabs.dynamic(tabsData)
end

---Builds the display for the per year option (without tabs)
---@param data table[]
---@param args table
---@return Html
function MediaList._displayByYear(data, args)
	local display = mw.html.create()

	for year, yearItems in Table.iter.spairs(MediaList._groupByYear(data), MediaList._sortInYear) do
		display
			:wikitext('\n====' .. year .. '====\n')
			:node(MediaList._displayYear(yearItems, args))
	end

	return display
end

---Groups provided data by year
---@param data table[]
---@return table[][]
function MediaList._groupByYear(data)
	local _, groupedData = Array.groupBy(data, function(item)
		return item.date:sub(1, 4)
	end)

	return groupedData
end

---Sort function to sort External Media Links within a year
---@param _ table?
---@param key1 string
---@param key2 string
---@return boolean
function MediaList._sortInYear(_, key1, key2)
	return key1 > key2
end

---Displays the External Media Links for a given data set (usually of a year)
---@param data table[]
---@param args table
---@return Html
function MediaList._displayYear(data, args)
	local yearDisplay = mw.html.create('ul')

	for _, item in ipairs(data) do
		yearDisplay:node(MediaList._row(item, args))
	end

	return yearDisplay
end

---Displays a single External Media Link
---@param item table
---@param args table
---@return Html
function MediaList._row(item, args)
	local row = mw.html.create('li')
		:node(MediaList._editButton(item.pagename))
		:node(MediaList._displayTeam(args.subjects[1], item.date))
		:wikitext(item.date .. NON_BREAKING_SPACE .. '|' .. NON_BREAKING_SPACE)

	if String.isNotEmpty(item.language) and item.language ~= 'en' and (item.language ~= 'usuk' or args.showUsUk) then
		row:wikitext(Flag.Icon({flag = item.language, shouldLink = false}) .. NON_BREAKING_SPACE)
	end

	row:node(MediaList._displayTitle(item))

	if String.isNotEmpty(item.translatedtitle) then
		row:wikitext(' ' .. mw.text.nowiki('[') .. item.translatedtitle .. mw.text.nowiki(']'))
	end

	local authors = {}
	for key, author in Table.iter.pairsByPrefix(item.authors, 'author') do
		local displayname = item.authors[key .. 'dn']
		if String.isNotEmpty(author) then
			table.insert(authors,
				Page.makeInternalLink({},
					String.isNotEmpty(displayname) and displayname or author,
					author
				)
			)
		end
	end
	if Table.isNotEmpty(authors) then
		row
			:wikitext(NON_BREAKING_SPACE .. 'by' .. NON_BREAKING_SPACE)
			:wikitext(mw.text.listToText(authors, ',' .. NON_BREAKING_SPACE, NON_BREAKING_SPACE .. 'and' .. NON_BREAKING_SPACE))
	end

	if String.isNotEmpty(item.publisher) then
		row:wikitext(NON_BREAKING_SPACE .. 'of' .. NON_BREAKING_SPACE .. '[[' .. item.publisher .. ']]')
	end

	if String.isNotEmpty(item.extradata.event) and not args.isEventPage then
		row:wikitext(MediaList._displayEvent(item))
	end

	if String.isNotEmpty(item.extradata.translation) then
		row:wikitext(MediaList._displayTranslation(item))
	end

	return row
end

---Display for the edit button in front of External Medial Link rows
---@param page string
---@return string
function MediaList._editButton(page)
	return mw.text.nowiki('[') .. '[[Data:' .. page .. '|e]]' .. mw.text.nowiki(']') .. NON_BREAKING_SPACE
end

---Displays the title for a given External Media Link
---@param item table
---@return Html
function MediaList._displayTitle(item)
	local title = item.link

	if String.isNotEmpty(item.title) then
		title = item.title
	end

	return mw.html.create('span')
			:addClass('plainlinks')
			:css('font-style', 'italic')
			:wikitext('[' .. item.link .. ' ' .. title .. ']')
end

---Displays the event for a given External Media Link
---@param item table
---@return string
function MediaList._displayEvent(item)
	local prefix = NON_BREAKING_SPACE .. 'at' .. NON_BREAKING_SPACE
	if Logic.readBoolOrNil(item.extradata.event_link) == false then
		return prefix .. item.extradata.event
	end

	if String.isNotEmpty(item.extradata.event_link) then
		return prefix .. '[[' .. item.extradata.event_link .. '|' .. item.extradata.event .. ']]'
	end

	return prefix .. '[[' .. item.extradata.event .. ']]'
end

---Displays the translation for a given External Media Link
---@param item table
---@return string
function MediaList._displayTranslation(item)
	local translation = NON_BREAKING_SPACE .. '(trans. '
		.. Flag.Icon({flag = item.extradata.translation, shouldLink = false})

	if String.isEmpty(item.extradata.translator) then
		return translation .. ')'
	end

	return translation .. NON_BREAKING_SPACE .. 'by' .. NON_BREAKING_SPACE .. item.extradata.translator .. ')'
end

---Displays the subject's team for a given External Media Link
---@param subject string
---@param date string
---@return Widget?
function MediaList._displayTeam(subject, date)
	local _, team = PlayerExt.syncTeam(subject, nil, {date = date})
	if not team then
		return
	end
	return TeamIconWidget{ teamTemplate = TeamTemplate.getRaw(team) }
end

---Displays the link to the Form with which External Media Links are to be created.
---@param show boolean defines if the link is to be displayed or not
---@return Html?
function MediaList._formLink(show)
	if not show then return end

	return mw.html.create('div')
		:css('display', 'block')
		:css('text-align', 'center')
		:css('padding', '0.5em')
		:node(mw.html.create('div')
			:css('display', 'inline')
			:css('white-space', 'nowrap')
			:wikitext(mw.text.nowiki('[')
				.. '[[Special:FormEdit/ExternalMediaLinks|Add an external media link]]'
				.. mw.text.nowiki(']')
			)
		)
end

return Class.export(MediaList)
