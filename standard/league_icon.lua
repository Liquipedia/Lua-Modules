---
-- @Liquipedia
-- wiki=commons
-- page=Module:LeagueIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local LeagueIcon = {}
local Class = require('Module:Class')
local Template = require('Module:Template')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')

local _FILLER = '<span class="league-icon-small-image">[[File:Logo filler event.png|link=]]</span>'

---display an image in the fashion of LeagueIconSmall templates
--i.e. it displays the icon in dark/light mode (depending on reader mode)
--in a span with customizable link, hooverDisplay
--
--can try to retrieve the icon(s) from existing LeagueIconSmall templates
function LeagueIcon.display(args)
	local options = args.options or {}

	local size = tonumber(args.size or '') or 50
	local iconDark = args.iconDark
	local icon = args.icon
	if not Logic.readBool(options.noTemplate) and not (icon and iconDark) then
		local stringOfExpandedTemplate = LeagueIcon.getTemplate({
			series = args.series,
			abbreviation = args.abbreviation,
			date = args.date
		})
		icon, iconDark = LeagueIcon.getIconFromTemplate({
			icon = icon,
			iconDark = iconDark,
			stringOfExpandedTemplate = stringOfExpandedTemplate
		})
	end

	--if icon is not given and can not be retrieved return empty string
	if String.isEmpty(icon) then
		return _FILLER
	end

	if String.isEmpty(iconDark) then
		iconDark = icon
	end

	local link
	if Logic.readBool(options.noLink) then
		link = ''
	else
		link = args.link or args.series or args.abbreviation or args.name or ''
	end
	return LeagueIcon._make(icon, iconDark, link, args.name, size)
end

function LeagueIcon._make(icon, iconDark, link, name, size)
	local imageOptions = '|link=' .. link .. '|' .. (name or link) .. '|' .. size .. 'x' .. size .. 'px]]'
	local lightSpan = mw.html.create('span')
		:addClass('league-icon-small-image lightmode')
		:wikitext('[[File:' .. icon .. imageOptions)
	local darkSpan = mw.html.create('span')
		:addClass('league-icon-small-image darkmode')
		:wikitext('[[File:' .. iconDark .. imageOptions)
	return tostring(lightSpan) .. tostring(darkSpan)
end

--retrieve icon and iconDark from LeagueIconSmall templates
--entry params:
--icon = icon for light mode
--iconDark = icon for dark mode
--stringOfExpandedTemplate = expanded LeagueIconSmall template as string
function LeagueIcon.getIconFromTemplate(args)
	args = args or {}
	local icon = args.icon
	local iconDark = args.iconDark
	local stringOfExpandedTemplate = args.stringOfExpandedTemplate

	--if LeagueIconSmall template exists retrieve the icons from it
	if stringOfExpandedTemplate then
		stringOfExpandedTemplate = mw.text.split(stringOfExpandedTemplate, 'File:')

		if String.isEmpty(icon) then
			--extract series icon from template:LeagueIconSmall
			icon = mw.text.split(stringOfExpandedTemplate[2] or '', '|')
			icon = icon[1]
		end

		--when Template:LeagueIconSmall has a darkmode icon retrieve that from the template too
		if String.isEmpty(iconDark) then
			iconDark = mw.text.split(stringOfExpandedTemplate[3] or '', '|')
			iconDark = iconDark[1]
			if String.isEmpty(iconDark) then
				iconDark = icon
			end
		end
	else
		icon = icon or ''
	end

	return icon, iconDark
end

function LeagueIcon.getTemplate(args)
	args = args or {}
	local series = args.series
	local abbreviation = args.abbreviation
	local date = args.date
	local frame = mw.getCurrentFrame()
	local stringOfExpandedTemplate = 'false'
	if not String.isEmpty(series) then
		stringOfExpandedTemplate = Template.safeExpand(
			frame,
			'LeagueIconSmall/' .. string.lower(series),
			{ date = date },
			'false'
		)
	end
	--if LeagueIconSmall template doesn't exist for the series try the abbreviation
	if stringOfExpandedTemplate == 'false' and not String.isEmpty(abbreviation) then
		stringOfExpandedTemplate = Template.safeExpand(
			frame,
			'LeagueIconSmall/' .. string.lower(abbreviation),
			{ date = date },
			'false'
		)
	end
	if stringOfExpandedTemplate == 'false' then
		return nil
	end
	return stringOfExpandedTemplate
end

--generate copy paste code for new LeagueIconSmall templates
--to be used with a form
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

	return '<pre class="selectall" width=50%>' .. mw.text.nowiki(
		'<span class="league-icon-small-image lightmode">' ..
		'[[File:' .. icon .. imageOptions .. '</span><!--\n' ..
		'--><span class="league-icon-small-image darkmode">' ..
		'[[File:' .. iconDark .. imageOptions .. '</span><!--\n' ..
		'--><noinclude>[[Category:Small League Icon Templates]]</noinclude>') .. '</pre>'
end

--generate copy paste code for new historical LeagueIconSmall templates
--to be used with a form
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
		) .. '</pre>'
end

return Class.export(LeagueIcon, { frameOnly = true })
