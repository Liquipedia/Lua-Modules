---
-- @Liquipedia
-- page=Module:LeagueIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local LeagueIcon = {}
local Class = Lua.import('Module:Class')
local Template = Lua.import('Module:Template')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local FILLER = '<span class="league-icon-small-image">[[File:Logo filler event.png|link=]]</span>'
local NO_ICON_BUT_ICONDARK_TRACKING_CATEGORY = '[[Category:Pages with only icondark]]'

---@class LeagueIconDisplayArgs
---@field icon string?
---@field iconDark string?
---@field link string?
---@field name string?
---@field date string?
---@field series string?
---@field abbreviation string?
---@field size number?
---@field options {noTemplate: boolean, noLink: boolean}?

---display an image in the fashion of LeagueIconSmall templates
--i.e. it displays the icon in dark/light mode (depending on reader mode)
--in a span with customizable link, hooverDisplay
--
--can try to retrieve the icon(s) from existing LeagueIconSmall templates
---@param args LeagueIconDisplayArgs
---@return string
function LeagueIcon.display(args)
	local options = args.options or {}

	local size = tonumber(args.size) or 50
	local iconDark = args.iconDark
	local icon = args.icon
	local trackingCategory = ''
	if not Logic.readBool(options.noTemplate) and String.isEmpty(icon) and String.isEmpty(iconDark) then
		local stringOfExpandedTemplate = LeagueIcon.getTemplate({
			series = args.series,
			abbreviation = args.abbreviation,
			date = args.date
		})
		icon, iconDark, trackingCategory = LeagueIcon.getIconFromTemplate({
			icon = icon,
			iconDark = iconDark,
			stringOfExpandedTemplate = stringOfExpandedTemplate
		})
	end

	--if icon and iconDark are not given and can not be retrieved return filler icon
	if String.isEmpty(icon) and String.isEmpty(iconDark) then
		return FILLER
	end

	if String.isEmpty(icon) then
		trackingCategory = NO_ICON_BUT_ICONDARK_TRACKING_CATEGORY
		icon = iconDark
	end
	---@cast icon -nil

	if String.isEmpty(iconDark) then
		iconDark = icon
	end
	---@cast iconDark -nil

	local link
	if Logic.readBool(options.noLink) then
		link = ''
	else
		link = args.link or args.series or args.abbreviation or args.name or ''
	end
	return LeagueIcon._make(icon, iconDark, link, args.name, size) .. trackingCategory
end

---@param icon string
---@param iconDark string
---@param link string
---@param name string
---@param size number
---@return string
function LeagueIcon._make(icon, iconDark, link, name, size)
	--remove "File:" prefix from icons due to legacy reasons
	--this should be removed once all wikis use the standardized infobox league
	icon = string.gsub(icon, '^File:', '')
	iconDark = string.gsub(iconDark, '^File:', '')

	local imageOptions = '|link=' .. link .. '|' .. (name or link) .. '|' .. size .. 'x' .. size .. 'px]]'

	if icon == iconDark then
		return tostring(mw.html.create('span')
		:addClass('league-icon-small-image')
		:wikitext('[[File:' .. icon .. imageOptions))
	end

	local lightSpan = mw.html.create('span')
		:addClass('league-icon-small-image lightmode')
		:wikitext('[[File:' .. icon .. imageOptions)
	local darkSpan = mw.html.create('span')
		:addClass('league-icon-small-image darkmode')
		:wikitext('[[File:' .. iconDark .. imageOptions)
	return tostring(lightSpan) .. tostring(darkSpan)
end

---Retrieve icon and iconDark from LeagueIconSmall templates
---@param args {icon: string?, iconDark: string?, stringOfExpandedTemplate: string?}
---@return string, string, string
function LeagueIcon.getIconFromTemplate(args)
	args = args or {}
	local trackingCategory = ''
	local icon = args.icon
	local iconDark = args.iconDark
	local stringOfExpandedTemplate = args.stringOfExpandedTemplate

	--if LeagueIconSmall template exists retrieve the icons from it
	if String.isEmpty(icon) and String.isEmpty(iconDark) and stringOfExpandedTemplate then
		local stringOfExpandedTemplateArray = mw.text.split(stringOfExpandedTemplate, 'File:')

		--extract series icon from template:LeagueIconSmall
		local iconArray = mw.text.split(stringOfExpandedTemplateArray[2] or '', '|')
		icon = iconArray[1]
		--when Template:LeagueIconSmall has a darkmode icon retrieve that from the template too
		if String.isEmpty(iconDark) then
			local iconDarkArray = mw.text.split(stringOfExpandedTemplateArray[3] or '', '|')
			iconDark = iconDarkArray[1]
		end
	elseif String.isEmpty(icon) then
		if String.isNotEmpty(iconDark) then
			trackingCategory = NO_ICON_BUT_ICONDARK_TRACKING_CATEGORY
		end
		icon = iconDark or ''
	end
	---@cast icon -nil

	if String.isEmpty(iconDark) then
		iconDark = icon
	end
	---@cast iconDark -nil

	return icon, iconDark, trackingCategory
end

---@param args {series: string?, abbreviation: string?, date: string?}
---@return string?
function LeagueIcon.getTemplate(args)
	args = args or {}
	local series = args.series
	local abbreviation = args.abbreviation
	local date = args.date
	local frame = mw.getCurrentFrame()
	local stringOfExpandedTemplate = 'false'
	if not String.isEmpty(series) then
		---@cast series -nil
		stringOfExpandedTemplate = Template.safeExpand(
			frame,
			'LeagueIconSmall/' .. string.lower(series),
			{ date = date },
			'false'
		)
	end
	--if LeagueIconSmall template doesn't exist for the series try the abbreviation
	if stringOfExpandedTemplate == 'false' and not String.isEmpty(abbreviation) then
		---@cast abbreviation -nil
		stringOfExpandedTemplate = Template.safeExpand(
			frame,
			'LeagueIconSmall/' .. string.lower(abbreviation),
			{date = date},
			'false'
		)
	end
	if stringOfExpandedTemplate == 'false' then
		return nil
	end
	return stringOfExpandedTemplate
end

---@class LeagueIconGenerateArgs
---@field icon string
---@field iconDark string?
---@field link string?
---@field name string?
---@field series string?

--generate copy paste code for new LeagueIconSmall templates
--to be used with a form
---@param args LeagueIconGenerateArgs
---@return string
function LeagueIcon.generate(args)
	local link = args.link or args.series
	if String.isEmpty(link) then
		error('No series/link specified')
	end
	local name = args.name or link

	local icon = args.icon
	if String.isEmpty(icon) then
		error('No icon file specified')
	end
	local iconDark = args.iconDark or icon

	local imageOptions = '|link={{{1|{{{link|' .. link .. '}}}}}}|{{{name|{{{1|{{{link|' .. name .. '}}}}}}}}}|50x50px]]'

	if icon == iconDark then
		return '<pre class="selectall" width=50%>' .. mw.text.nowiki(
			'<span class="league-icon-small-image">' ..
			'[[File:' .. icon .. imageOptions .. '</span><!--\n' ..
			'--><noinclude>[[Category:Small League Icon Templates]]</noinclude>') .. '</pre>'
			.. LeagueIcon._buildLinkToTemplate(args)
	end

	return '<pre class="selectall" width=50%>' .. mw.text.nowiki(
		'<span class="league-icon-small-image lightmode">' ..
		'[[File:' .. icon .. imageOptions .. '</span><!--\n' ..
		'--><span class="league-icon-small-image darkmode">' ..
		'[[File:' .. iconDark .. imageOptions .. '</span><!--\n' ..
		'--><noinclude>[[Category:Small League Icon Templates]]</noinclude>') .. '</pre>'
		.. LeagueIcon._buildLinkToTemplate(args)
end

--generate copy paste code for new historical LeagueIconSmall templates
--to be used with a form
---@param args table
---@return string
function LeagueIcon.generateHistorical(args)
	local title = args.title or args.series
	if String.isEmpty(title) then
		error('No template title specified')
	end
	local link = args.link or title
	local name = args.name or link
	local timeName = title:lower() .. 'time'

	local currentSubTemplate = args.subtemplate0
	local switchDate = args.date1
	local nextSubTemplate = args.subtemplate1
	if String.isEmpty(currentSubTemplate) or String.isEmpty(switchDate) or String.isEmpty(nextSubTemplate) then
		error('Missing mandatory subtemplate or switch date')
	end

	local defineTime = '{{#vardefine:' .. timeName .. '|{{#time:U|{{{date|{{#replace:{{#replace:{{#explode:'
		.. '{{#var:date|{{#var:edate|{{#var:sdate|{{CURRENTYEAR}}-{{CURRENTMONTH}}-{{CURRENTDAY2}}}}}}}}'
		.. '|<}}|-XX|}}|-??|}}}}}}}}}<!-- this variable name needs to be unique --><!--\n'

	local comparisons = '{{#time:U|' .. switchDate .. '}} < {{#var:' .. timeName .. '}}|'
			.. '{{LeagueIconSmall/' .. nextSubTemplate:lower() .. '|link={{{link|' .. link .. '}}}'
			.. '|name={{{name|' .. name .. '}}} }}}}<!--\n'
			.. '-->{{#ifexpr:{{#time:U|' .. switchDate .. '}} >= {{#var:' .. timeName .. '}}|'
			.. '{{LeagueIconSmall/' .. currentSubTemplate:lower() .. '|link={{{link|' .. link .. '}}}'
			.. '|name={{{name|' .. name .. '}}} }}}}<!--\n'

	local index = 2
	currentSubTemplate = nextSubTemplate
	switchDate = args['date' .. index]
	nextSubTemplate = args['subtemplate' .. index]

	while not (String.isEmpty(currentSubTemplate) or String.isEmpty(switchDate) or String.isEmpty(nextSubTemplate)) do
		comparisons = '{{#time:U|' .. switchDate .. '}} < {{#var:' .. timeName .. '}}|'
			.. '{{LeagueIconSmall/' .. nextSubTemplate:lower() .. '|link={{{link|' .. link .. '}}}'
			.. '|name={{{name|' .. name .. '}}} }}}}<!--\n'
			.. '-->{{#ifexpr:{{#time:U|' .. switchDate .. '}} >= {{#var:' .. timeName .. '}} AND '
			.. comparisons
		index = index + 1
		currentSubTemplate = nextSubTemplate
		switchDate = args['date' .. index]
		nextSubTemplate = args['subtemplate' .. index]
	end
	comparisons = '-->{{#ifexpr:' .. comparisons

	return '<pre class="selectall" width=50%>' .. mw.text.nowiki(
			defineTime .. comparisons .. '--><noinclude>[[Category:Historical Small League Icon template]]</noinclude>'
		) .. '</pre>' .. LeagueIcon._buildLinkToTemplate(args)
end

---@param args {templateName: string?, wiki: string?}
---@return string
function LeagueIcon._buildLinkToTemplate(args)
	if String.isEmpty(args.templateName) or String.isEmpty(args.wiki) then
		return ''
	end

	return '<br><b>Link to the template page:</b> [[' .. args.wiki ..
		':Template:LeagueIconSmall/' .. args.templateName:lower() .. ']]'
end

return Class.export(LeagueIcon, {frameOnly = true, exports = {
	'display',
	'getIconFromTemplate',
	'getTemplate',
	'generate',
	'generateHistorical',
}})
