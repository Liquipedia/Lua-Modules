---
-- @Liquipedia
-- page=Module:ExternalMediaLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local ExternalMediaLink = {}

local MAXIMUM_VALUES = {
	subjects = 20,
	organisations = 5,
	authors = 5,
}
local DEFAULT_LANGUAGE = 'en'
local NON_BREAKING_SPACE = '&nbsp;'

---Main function for External Media Links.
---Calls storage and display (if not disabled).
---@param args table
---@return Html?
function ExternalMediaLink.run(args)
	ExternalMediaLink._fallBackArgs(args)

	if Logic.nilOr(Logic.readBoolOrNil(args.storage), true)
		and not Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then

		ExternalMediaLink._store(args)
	end

	mw.ext.TeamLiquidIntegration.add_category('Pages with ExternalMediaLinks')
	if not Logic.nilOr(Logic.readBoolOrNil(args.display), true) then
		return
	end

	return ExternalMediaLink._display(args)
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

---Stores an External Media Link to Lpdb
---@param args table
function ExternalMediaLink._store(args)
	local lpdbData = {
		date = args.date,
		language = args.language or DEFAULT_LANGUAGE,
		title = args.title,
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
	lpdbData.authors = mw.ext.LiquipediaDB.lpdb_create_json(authors)

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

	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(Table.merge(extradata, orgs, subjects))

	mw.ext.LiquipediaDB.lpdb_externalmedialink(ExternalMediaLink._objectName(args), lpdbData)
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
---@param args table
---@return Html
function ExternalMediaLink._display(args)
	local display = mw.html.create()

	if args.date then
		display:wikitext(args.date .. NON_BREAKING_SPACE .. '|' .. NON_BREAKING_SPACE)
	end

	if args.language and args.language ~= DEFAULT_LANGUAGE then
		display:wikitext(Flags.Icon{flag = args.language, shouldLink = false} .. NON_BREAKING_SPACE)
	end

	if args.title then
		display:tag('span')
			:addClass('plainlinks')
			:css('font-style', 'italic')
			:wikitext(Page.makeExternalLink(args.title, args.link))
	else
		display:tag('span')
			:addClass('plainlinks')
			:wikitext(Page.makeExternalLink(args.link, args.link))
	end

	if args.trans_title then
		display:wikitext(NON_BREAKING_SPACE .. '[' .. args.trans_title .. ']')
	end

	local authors = {}
	for _, author, authorIndex in Table.iter.pairsByPrefix(args, 'by') do
		table.insert(authors, Page.makeInternalLink({}, author, args['by_link' .. authorIndex]))
	end
	if Table.isNotEmpty(authors) then
		display
			:wikitext(NON_BREAKING_SPACE .. 'by' .. NON_BREAKING_SPACE)
			:wikitext(mw.text.listToText(authors, ',' .. NON_BREAKING_SPACE, NON_BREAKING_SPACE .. 'and' .. NON_BREAKING_SPACE))
	end

	if args.of then
		display:wikitext(NON_BREAKING_SPACE .. 'of' .. NON_BREAKING_SPACE .. Page.makeInternalLink({}, args.of))
	end

	if args.event then
		display:wikitext(ExternalMediaLink._displayEvent(args))
	end

	if args.translation then
		display:wikitext(ExternalMediaLink._displayTranslation(args))
	end

	if args.note then
		display
			:wikitext(NON_BREAKING_SPACE)
			:tag('span')
				:css('font-style', 'italic')
				:wikitext('(' .. args.note .. ')')
	end

	return display
end

---Builds the event display for an External Media Link
---@param args table
---@return string
function ExternalMediaLink._displayEvent(args)
	local prefix = NON_BREAKING_SPACE .. 'at' .. NON_BREAKING_SPACE

	if Logic.readBoolOrNil(args['event-link']) == false then
		return prefix .. args.event
	end

	return prefix .. Page.makeInternalLink({}, args.event, args['event-link'])
end

---Builds the translation display for an External Media Link
---@param args table
---@return string
function ExternalMediaLink._displayTranslation(args)
	local translation = NON_BREAKING_SPACE .. '(trans. '
		.. Flags.Icon{flag = args.translation, shouldLink = false}

	if String.isEmpty(args.translator) then
		return translation .. ')'
	end

	return translation .. NON_BREAKING_SPACE .. 'by' .. NON_BREAKING_SPACE .. args.translator .. ')'
end

---Wrapper function for External Media Link display in the Data namespace
---@param args table
---@return Html
function ExternalMediaLink.wrapper(args)
	local wrapperInfoDisplay = mw.html.create('table')
		:attr('border', 0)
		:attr('cellpadding', 4)
		:attr('cellspacing', 4)
		:css('margin-bottom', '5px')

	wrapperInfoDisplay
		:tag('tr')
			:tag('th'):wikitext('Author(s)'):done()
			:tag('td'):wikitext(args.authors or ''):done():done()
		:tag('tr')
			:tag('th'):wikitext('Title'):done()
			:tag('td'):wikitext(args.title or ''):done():done()
		:tag('tr')
			:tag('th'):wikitext('Date'):done()
			:tag('td'):wikitext(args.date or ''):done():done()
		:tag('tr')
			:tag('th'):wikitext('URL'):done()
			:tag('td'):wikitext(args.link or '')

	local parsedArgs = {
		date = args.date,
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
		local authors = Array.map(mw.text.split(args.authors, ','), ExternalMediaLink._cleanValue)
		args.by_link1 = args.by_link1 or args.by_link
		for authorIndex, author in pairs(authors) do
			parsedArgs['by' .. authorIndex] = author
			parsedArgs['by_link' .. authorIndex] = args['by_link' .. authorIndex]
		end
	end

	if args.subjects then
		local subjects = Array.map(mw.text.split(args.subjects, ','), ExternalMediaLink._cleanValue)
		for subjectIndex, subject in pairs(subjects) do
			parsedArgs['subject' .. subjectIndex] = subject
		end
	end

	if args.subject_organizations then
		local orgs = Array.map(mw.text.split(args.subject_organizations, ','), ExternalMediaLink._cleanValue)
		for orgIndex, org in pairs(orgs) do
			parsedArgs['subject_organization' .. orgIndex] = org
		end
	end

	return mw.html.create()
		:wikitext('[[Special:FormEdit/ExternalMediaLinks|Go back to the form]]<br>')
		:node(ExternalMediaLink.run(parsedArgs))
		:node(wrapperInfoDisplay)
end

---Remove whitespace from the beginning and end of a string. Returns nil if empty string remains.
---@param value string
---@return string?
function ExternalMediaLink._cleanValue(value)
	return String.nilIfEmpty(mw.text.trim(value))
end

return Class.export(ExternalMediaLink, {exports = {'run', 'wrapper'}})
