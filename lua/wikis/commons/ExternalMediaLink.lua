---
-- @Liquipedia
-- page=Module:ExternalMediaLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local ExternalMediaLinkDisplay = Lua.import('Module:Widget/ExternalMedia/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local ExternalMediaLink = {}

local MAXIMUM_VALUES = {
	subjects = 20,
	organisations = 5,
	authors = 5,
}
local DEFAULT_LANGUAGE = 'en'

---Main function for External Media Links.
---Calls storage and display (if not disabled).
---@param args table
---@return Widget?
function ExternalMediaLink.run(args)
	ExternalMediaLink._fallBackArgs(args)
	local parsedData = ExternalMediaLink._readArgs(args)

	if Logic.nilOr(Logic.readBoolOrNil(args.storage), true) and Lpdb.isStorageEnabled() then

		mw.ext.LiquipediaDB.lpdb_externalmedialink(
			ExternalMediaLink._objectName(args), Json.stringifySubTables(parsedData)
		)
	end

	mw.ext.TeamLiquidIntegration.add_category('Pages with ExternalMediaLinks')
	if not Logic.nilOr(Logic.readBoolOrNil(args.display), true) then
		return
	end

	return ExternalMediaLink._display(parsedData, args.note)
end

---Applies fallback and alias args
---@param args table
function ExternalMediaLink._fallBackArgs(args)
	args.by_link1 = args.by_link1 or args.by_link
	args.by1 = args.by1 or args.by
	args.subject1 = args.subject1 or args.subject or args.player or args.interviewee
	args.subject_organization1 = args.subject_organization1 or args.subject_organization

	for subjectIndex = 2, MAXIMUM_VALUES.subjects do
		args['subject' .. subjectIndex] = args['subject' .. subjectIndex] or args['player' .. subjectIndex]
	end
end

---Parses the supplied arguments and returns as LPDB form
---@param args table
---@return table
function ExternalMediaLink._readArgs(args)
	local lpdbData = {
		date = DateExt.toYmdInUtc(args.date),
		language = args.language or DEFAULT_LANGUAGE,
		title = mw.text.unstripNoWiki(args.title),
		translatedtitle = args.trans_title,
		link = args.link,
		publisher = args.of,
		type = args.type,
	}

	local authors = {}
	for _, author, authorIndex in Table.iter.pairsByPrefix(args, 'by') do
		authors['author' .. authorIndex] = Page.pageifyLink(args['by_link' .. authorIndex] or author)
		authors['author' .. authorIndex .. 'dn'] = author
	end
	-- set a maximum for authors due to the same being used in queries
	assert(Table.size(authors) <= 2 * MAXIMUM_VALUES.authors,
		'Maximum Value of authors (' .. MAXIMUM_VALUES.authors .. ') exceeded')
	lpdbData.authors = authors

	local extradata = {
		translation = args.translation,
		translator = args.translator,
		event = args.event,
		event_link = Page.pageifyLink(
			Logic.emptyOr(args['event-link'], args.event) or ''
		),
		subject_organization = args.subject_organization1, --legacy
	}

	local orgs = {}
	for _, org, orgIndex in Table.iter.pairsByPrefix(args, 'subject_organization') do
		orgs['subject_organization' .. orgIndex] = Page.pageifyLink(org)
	end
	-- set a maximum for orgs due to the same being used in queries
	assert(Table.size(orgs) <= MAXIMUM_VALUES.organisations,
		'Maximum Value of organisations subjects (' .. MAXIMUM_VALUES.organisations .. ') exceeded')

	local subjects = {}
	for _, subject, subjectIndex in Table.iter.pairsByPrefix(args, 'subject') do
		subjects['subject' .. subjectIndex] = Page.pageifyLink(subject)
	end
	-- set a maximum for subjects due to the same being used in queries
	assert(Table.size(subjects) <= MAXIMUM_VALUES.subjects,
		'Maximum Value of subjects (' .. MAXIMUM_VALUES.subjects .. ') exceeded')

	lpdbData.extradata = Table.merge(extradata, orgs, subjects)

	return lpdbData
end

---Builds the object name for an External Media Link
---@param args table
---@return string
function ExternalMediaLink._objectName(args)
	local objectName = 'ExternalMediaLink'

	for _, author in Table.iter.pairsByPrefix(args, 'by') do
		objectName = objectName .. '_' .. author
	end

	return objectName .. '_' .. (args.date or '')
end

---Builds the display for an External Media Link
---@param data table
---@param note string?
---@return Widget
function ExternalMediaLink._display(data, note)
	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		ExternalMediaLinkDisplay{data = data},
		Logic.isNotEmpty(note) and {
			'&nbsp;',
			HtmlWidgets.Span{
				css = {['font-style'] = 'italic'},
				children = {'(', note, ')'},
			}
		}
	)}
end

---Wrapper function for External Media Link display in the Data namespace
---@param args table
---@return Widget
function ExternalMediaLink.wrapper(args)
	local parsedArgs = {
		date = DateExt.toYmdInUtc(args.date),
		link = args.link,
		title = args.title,
		type = args.type and args.type:lower() or nil,
		of = args.of,
		event = args.event,
		['event-link'] = args['event-link'],
		language = args.language,
		translation = args.translation,
		translator = args.translator,
		trans_title = args.trans_title,
	}

	if args.authors then
		local authors = Array.parseCommaSeparatedString(args.authors)
		args.by_link1 = args.by_link1 or args.by_link
		for authorIndex, author in pairs(authors) do
			parsedArgs['by' .. authorIndex] = author
			parsedArgs['by_link' .. authorIndex] = args['by_link' .. authorIndex]
		end
	end

	if args.subjects then
		local subjects = Array.parseCommaSeparatedString(args.subjects)
		for subjectIndex, subject in pairs(subjects) do
			parsedArgs['subject' .. subjectIndex] = subject
		end
	end

	if args.subject_organizations then
		local orgs = Array.parseCommaSeparatedString(args.subject_organizations)
		for orgIndex, org in pairs(orgs) do
			parsedArgs['subject_organization' .. orgIndex] = org
		end
	end

	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		Link{link = 'Special:FormEdit/ExternalMediaLinks', children = 'Go back to the form'},
		HtmlWidgets.Br{},
		ExternalMediaLink.run(parsedArgs),
		ExternalMediaLink._wrapperDisplay(parsedArgs)
	)}
end

---@private
---@param parsedArgs table
---@return Widget
function ExternalMediaLink._wrapperDisplay(parsedArgs)
	---@param prefix string
	---@param linkPrefix string?
	---@return Widget[]
	local makeLinkList = function(prefix, linkPrefix)
		local list = Array.mapIndexes(function(index)
			if Logic.isEmpty(parsedArgs[prefix .. index]) then
				return
			end
			return Link{
				link = linkPrefix and parsedArgs[linkPrefix .. index] or parsedArgs[prefix .. index],
				children = parsedArgs[prefix .. index],
			}
		end)
		return Array.interleave(list, ', ')
	end

	---@param desc string
	---@param data Widget[]|Widget?
	---@return Widget?
	local rowIfNotEmpty = function(desc, data)
		if Logic.isEmpty(data) then
			return
		end
		return TableWidgets.Row{children = {
			TableWidgets.CellHeader{children = desc},
			TableWidgets.Cell{children = data},
		}}
	end

	return TableWidgets.Table{
		sortable = false,
		columns = {{}, {}},
		children = {TableWidgets.TableBody{children = WidgetUtil.collect(
			rowIfNotEmpty('Title', parsedArgs.title),
			rowIfNotEmpty('Author(s)', makeLinkList('by', 'by_link')),
			rowIfNotEmpty('Date', parsedArgs.date),
			rowIfNotEmpty('Subject(s)', makeLinkList('subject')),
			rowIfNotEmpty('Org Subject(s)', makeLinkList('subject_organization')),
			rowIfNotEmpty('Event', parsedArgs.event and Link{
				link = parsedArgs['event-link'] or parsedArgs.event,
				children = parsedArgs.event,
			} or nil),
			rowIfNotEmpty('URL', parsedArgs.link)
		)}},
	}
end

return Class.export(ExternalMediaLink, {exports = {'run', 'wrapper'}})
