   
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

---display an image in LeagueIconSmall fashion
--can directly expand the LeagueIconSmall/... template
--or try to use a passed icon (and iconDark) first
function LeagueIcon.display(args)
	local options = args.options or {}

	local size = tonumber(args.size or '') or 50
	local iconDark = args.iconDark
	local icon = args.icon
	if not Logic.readBool(options.noTemplate) and not (icon and iconDark) then
		icon, iconDark = LeagueIcon.getIconFromTemplate(icon, iconDark, args.series, args.abbreviation, args.date)
	end

	--if icon is not given and can not be retrieved return empty string
	if String.isEmpty(icon) then
		return ''
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
		:wikitext('[[File:' .. icon .. imageOptions)
	return mw.html.create('span'):node(lightSpan):node(darkSpan)
end

--retrieve icon and iconDark from LeagueIconSmall templates
function LeagueIcon.getIconFromTemplate(icon, iconDark, series, abbreviation, date)
	local leagueIconSmallTemplate = LeagueIcon._getTemplate(series, abbreviation, date)

	--if LeagueIconSmall template exists retrieve the icons from it
	if leagueIconSmallTemplate then
		if String.isEmpty(icon) then
			--extract series icon from template:LeagueIconSmall
			leagueIconSmallTemplate = mw.text.split(leagueIconSmallTemplate, 'File:')
			icon = mw.text.split(leagueIconSmallTemplate[2] or '', '|')
			icon = icon[1]
		end

		--when Template:LeagueIconSmall has a darkmode icon retrieve that from the template too
		if String.isEmpty(iconDark) then
			iconDark = mw.text.split(leagueIconSmallTemplate[3] or '', '|')
			iconDark = iconDark[1]
		end
	else
		icon = icon or ''
	end

	return icon, iconDark
end

function LeagueIcon._getTemplate(series, abbreviation, date)
	local frame = mw.getCurrentFrame()
	local leagueIconSmallTemplate = 'false'
	if not String.isEmpty(series) then
		leagueIconSmallTemplate = Template.safeExpand(
			frame,
			'LeagueIconSmall/' .. string.lower(series),
			{ date = date },
			'false'
		)
	end
	--if LeagueIconSmall template doesn't exist for the series try the abbreviation
	if leagueIconSmallTemplate == 'false' and not String.isEmpty(abbreviation) then
		leagueIconSmallTemplate = Template.safeExpand(
			frame,
			'LeagueIconSmall/' .. string.lower(abbreviation),
			{ date = date },
			'false'
		)
	end
	if leagueIconSmallTemplate == 'false' then
		return nil
	end
	return leagueIconSmallTemplate
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

	local imageOptions = '|link=' .. link .. '|' .. name .. '|50x50px]]'

	return '<pre class="selectall" width=50%>' .. mw.text.nowiki('<span><!--\n' ..
		'--><span class="league-icon-small-image lightmode">' ..
		'[[File:' .. icon .. imageOptions .. '</span><!--\n' ..
		'--><span class="league-icon-small-image darkmode">' ..
		'[[File:' .. iconDark .. imageOptions .. '</span><!--\n' ..
		'--></span><noinclude>[[Category:Small League Icon Templates]]</noinclude>') .. '</pre>'
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
