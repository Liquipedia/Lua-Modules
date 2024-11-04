---
-- @Liquipedia
-- wiki=commons
-- page=Module:Mock/TeamTemplate
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- Warning: This mock ignores the posibility of image/imagedark being unset/empty
-- and never uses legacyimage/legacyimagedark for that reason

local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local MockData = Lua.import('test_assets.team_template_data')

local NOT_FOUND_ERROR = '<div class="error">No team template exists for name "${name}".</div>'
local MISSING_INPUT_ERROR = 'bad argument #1 to "name" (string or number expected, got nil)'

local mockTeamTemplate = {}

-- temp copy the orig functions so we can retrieve them later again when tearing down the mock
local _teamTemplate = Table.copy(mw.ext.TeamTemplate)

function mockTeamTemplate.setUp()
	mw.ext.TeamTemplate.raw = mockTeamTemplate.raw
	mw.ext.TeamTemplate.raw_historical = mockTeamTemplate.raw_historical
	mw.ext.TeamTemplate.teamexists = mockTeamTemplate.teamexists
	mw.ext.TeamTemplate.team = mockTeamTemplate.team
	mw.ext.TeamTemplate.team2 = mockTeamTemplate.team2
	mw.ext.TeamTemplate.teamshort = mockTeamTemplate.teamshort
	mw.ext.TeamTemplate.team2short = mockTeamTemplate.team2short
	mw.ext.TeamTemplate.teambracket = mockTeamTemplate.teambracket
	mw.ext.TeamTemplate.teamicon = mockTeamTemplate.teamicon
	mw.ext.TeamTemplate.teamimage = mockTeamTemplate.teamimage
	mw.ext.TeamTemplate.teampage = mockTeamTemplate.teampage
	mw.ext.TeamTemplate.teampart = mockTeamTemplate.teampart
	mw.ext.TeamTemplate.raw = mockTeamTemplate.raw
end

function mockTeamTemplate.tearDown()
	mw.ext.TeamTemplate = _teamTemplate
end

---@param teamtemplate string
---@param date string|number?
---@return teamTemplateData?
function mockTeamTemplate.raw(teamtemplate, date)
	assert(type(teamtemplate) == 'string', MISSING_INPUT_ERROR)
	local cleanedInput = teamtemplate:lower():gsub('_', ' ')
	local found = MockData[cleanedInput]
	if not found then return end

	if found.templatename then
		return found
	end

	local historicals = {}
	for startDate, teamTemplateName in pairs(found) do
		table.insert(historicals, {startDate = startDate, name = teamTemplateName})
	end
	table.sort(historicals, function(a, b) return a.startDate < b.startDate end)

	-- can not use DateExt.toYmdInUtc as mw.getContentLanguage():formatDate is not mocked
	local standardizedDate
	if type(date) == 'number' then
		standardizedDate = os.date('%F', date)
	else
		standardizedDate = String.nilIfEmpty(date) or os.date('%F') --[[@as string]]
	end

	for index, info in ipairs(historicals) do
		local endDate = (historicals[index + 1] or {}).startDate or os.date('%F')
		if standardizedDate >= info.startDate and standardizedDate <= endDate then
			return MockData[info.name]
		end
	end
end

---@param teamtemplate string
---@return {[string]: string}? ## key is formated as `YYYY-MM-DD`and values are team template names
function mockTeamTemplate.raw_historical(teamtemplate)
	assert(type(teamtemplate) == 'string', MISSING_INPUT_ERROR)
	local cleanedInput = teamtemplate:lower():gsub('_', ' ')
	local found = MockData[cleanedInput]
	if found and not found.templatename then
		return found
	end
end

---@param teamtemplate string
---@return boolean
function mockTeamTemplate.teamexists(teamtemplate)
	assert(type(teamtemplate) == 'string', MISSING_INPUT_ERROR)
	local cleanedInput = teamtemplate:lower():gsub('_', ' ')
	return MockData[cleanedInput] ~= nil
end

---@param str string
---@param teamtemplate string
---@param date string|number?
---@return string
function mockTeamTemplate._fetch(str, teamtemplate, date)
	assert(type(teamtemplate) == 'string', MISSING_INPUT_ERROR)
	local found = mockTeamTemplate.raw(teamtemplate, date)
	if not found then
		return String.interpolate(NOT_FOUND_ERROR, {name = teamtemplate})
	end

	return String.interpolate(str, found)
end

---@param teamtemplate string
---@param date string|number?
---@return string
function mockTeamTemplate.team(teamtemplate, date)
	return mockTeamTemplate._fetch(
		'<span data-highlightingclass="${name}" class="team-template-team-standard">'
			.. '<span class="team-template-image-icon team-template-lightmode">'
				.. '[[File:${image}|100x50px|middle|${name}|link=${page}]]</span>'
			.. '<span class="team-template-image-icon team-template-darkmode">'
				.. '[[File:${imagedark}|100x50px|middle|${name}|link=${page}]]</span>'
			.. ' <span class="team-template-text">[[${page}|${name}]]</span>'
			.. '</span>',
		teamtemplate,
		date
	)
end

---@param teamtemplate string
---@param date string|number?
---@return string
function mockTeamTemplate.team2(teamtemplate, date)
	return mockTeamTemplate._fetch(
		'<span data-highlightingclass="${name}" class="team-template-team2-standard">'
			.. '<span class="team-template-text">[[${page}|${name}]]</span> '
			.. '<span class="team-template-image-icon team-template-lightmode">'
				.. '[[File:${image}|100x50px|middle|${name}|link=${page}]]</span>'
			.. '<span class="team-template-image-icon team-template-darkmode">'
				.. '[[File:${imagedark}|100x50px|middle|${name}|link=${page}]]</span>'
			.. '</span>',
		teamtemplate,
		date
	)
end

---@param teamtemplate string
---@param date string|number?
---@return string
function mockTeamTemplate.teamshort(teamtemplate, date)
	return mockTeamTemplate._fetch(
		'<span data-highlightingclass="${name}" class="team-template-team-short">'
			.. '<span class="team-template-image-icon team-template-lightmode">'
				.. '[[File:${image}|100x50px|middle|${name}|link=${page}]]</span>'
			.. '<span class="team-template-image-icon team-template-darkmode">'
				.. '[[File:${imagedark}|100x50px|middle|${name}|link=${page}]]</span>'
			.. ' <span class="team-template-text">[[${page}|${shortname}]]</span>'
			.. '</span>',
		teamtemplate,
		date
	)
end

---@param teamtemplate string
---@param date string|number?
---@return string
function mockTeamTemplate.team2short(teamtemplate, date)
	return mockTeamTemplate._fetch(
		'<span data-highlightingclass="${name}" class="team-template-team2-short">'
			.. '<span class="team-template-text">[[${page}|${shortname}]]</span> '
			.. '<span class="team-template-image-icon team-template-lightmode">'
				.. '[[File:${image}|100x50px|middle|${name}|link=${page}]]</span>'
			.. '<span class="team-template-image-icon team-template-darkmode">'
				.. '[[File:${imagedark}|100x50px|middle|${name}|link=${page}]]</span>'
			.. '</span>',
		teamtemplate,
		date
	)
end

---@param teamtemplate string
---@param date string|number?
---@return string
function mockTeamTemplate.teambracket(teamtemplate, date)
	return mockTeamTemplate._fetch(
		'<span data-highlightingclass="${name}" class="team-template-team-bracket">'
			.. '<span class="team-template-image-icon team-template-lightmode">'
				.. '[[File:${image}|100x50px|middle|${name}|link=]]</span>'
			.. '<span class="team-template-image-icon team-template-darkmode">'
				.. '[[File:${imagedark}|100x50px|middle|${name}|link=]]</span>'
			.. ' <span class="team-template-text">${bracketname}</span>'
			.. '</span>',
		teamtemplate,
		date
	)
end

---@param teamtemplate string
---@param date string|number?
---@return string
function mockTeamTemplate.teamicon(teamtemplate, date)
	return mockTeamTemplate._fetch(
		'<span data-highlightingclass="${name}" class="team-template-team-icon">'
			.. '<span class="team-template-image-icon team-template-lightmode">'
				.. '[[File:${image}|100x50px|middle|${name}|link=${page}]]</span>'
			.. '<span class="team-template-image-icon team-template-darkmode">'
				.. '[[File:${imagedark}|100x50px|middle|${name}|link=${page}]]</span>'
			.. '</span>',
		teamtemplate,
		date
	)
end

---@param teamtemplate string
---@param date string|number?
---@return string
function mockTeamTemplate.teamimage(teamtemplate, date)
	return mockTeamTemplate._fetch(
		'<span data-highlightingclass="${name}" class="team-template-team-image">'
			.. '<span class="team-template-image-big team-template-lightmode">'
				.. '[[File:${image}|100x50px|middle|${name}|link=${page}]]</span>'
			.. '</span>',
		teamtemplate,
		date
	)
end

---@param teamtemplate string
---@param date string|number?
---@return string
function mockTeamTemplate.teampage(teamtemplate, date)
	return mockTeamTemplate._fetch(
		'${page}',
		teamtemplate,
		date
	)
end

---@param teamtemplate string
---@param date string|number?
---@return string
function mockTeamTemplate.teampart(teamtemplate, date)
	return mockTeamTemplate._fetch(
		'<div data-highlightingclass="${name}" class="team-template-team-part">'
			.. '<span class="team-template-image-icon team-template-lightmode">'
				.. '[[File:${image}|100x50px|middle|${name}|link=${page}]]</span>'
			.. '<span class="team-template-image-icon team-template-darkmode">'
				.. '[[File:${imagedark}|100x50px|middle|${name}|link=${page}]]</span>'
			.. '</div>',
		teamtemplate,
		date
	)
end

return mockTeamTemplate
