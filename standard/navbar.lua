local Class = require('Module:Class')
local Logic = require('Module:Logic')

local NavBar = {}

--legacy entry points
function NavBar.navbar(args, headerText)
	headerText = headerText or args[1]
	return NavBar.NavBar(args, headerText)
end
function NavBar._navbar(args, headerText)
	headerText = headerText or args[1]
	return NavBar.NavBar(args, headerText)
end

local _BRACKETS_LEFT = '&#91;'
local _BRACKETS_RIGHT = '&#93;'

function NavBar.NavBar(args, headerText)
	local showBrackets = Logic.readBool(args.brackets)
	local isCollapsible = Logic.readBool(args.collapsible)
	local isPlain = Logic.readBool(args.plain)
	local isMini = Logic.readBool(args.mini)
	if (not isPlain) and isCollapsible then
		isMini = true
	end

	local fontStyle = args.fontstyle
	if isCollapsible and args.fontcolor then
		fontStyle = 'color:' .. args.fontcolor .. ';'
	end

	local navBarDiv = mw.html.create('div')
		:addClass('noprint')
		:addClass('plainlinks')
		:addClass('navbox-navbar')
		:css('padding', '0')
		:css('font-size', 'xx-small')
	if isCollapsible then
		navBarDiv:css('float', 'left'):css('text-align', 'left')
	else
		navBarDiv:cssText(args.style)
	end
	if isMini then
		navBarDiv:addClass('mini')
	end
	if not isMini and not isPlain then
		navBarDiv:node(mw.html.create('span')
			:css('word-spacing', 0)
			:cssText(fontStyle)
			:wikitext(args.text or 'This box:')
			:wikitext(' ')
		)
	end

	local templateTitle = NavBar._getTitle(args.titleArg)
	local talkpage = templateTitle.talkPageTitle and templateTitle.talkPageTitle.fullText or ''

	if showBrackets then
		navBarDiv:node(mw.html.create('span')
			:css('margin-right', '-0.125em')
			:cssText(fontStyle)
			:wikitext(_BRACKETS_LEFT .. ' ')
		)
	end

	local shortcutObjects = {
		{long = 'view', short = 'v', text = 'View this template', link = templateTitle.fullText},
		{long = 'talk', short = 'd', text = 'Discuss this template', link = talkpage},
	}
	if not Logic.readBool(args.noedit) then
		table.insert(
			shortcutObjects,
			{
				long = 'edit',
				short = 'e',
				text = 'Edit this template',
				link = templateTitle:fullUrl('action=edit'),
				externalLink = true
			}
		)
	end

	local shortcuts = mw.html.create('ul')
		:addClass('hlist')

	for _, item in ipairs(shortcutObjects) do
		shortcuts:tag('li')
			:addClass('nv-' .. item.long)
			:wikitext(item.externalLink and '[' or '[[')
			:wikitext(item.link .. '|')
			:tag(isMini and 'abbr' or 'span')
				:attr('title', item.text)
				:cssText(fontStyle)
				:wikitext(isMini and item.short or item.long)
				:done()
			:wikitext(item.externalLink and ']' or ']]')
			:done()
	end

	navBarDiv:node(shortcuts)

	if showBrackets then
		navBarDiv:node(mw.html.create('span')
			:css('margin-left', '-0.125em')
			:cssText(fontStyle)
			:wikitext(' ' .. _BRACKETS_RIGHT)
		)
	end

	navBarDiv = tostring(navBarDiv)

	if isCollapsible then
		navBarDiv = navBarDiv .. tostring(mw.html.create('div')
			:css('font-size', '114%')
			:css('margin', isMini and '0 4em' or '0 7em')
			:cssText(fontStyle)
			:wikitext(headerText)
		)
	end

	return navBarDiv
end

function NavBar._getTitle(titleArg)
	--if no template title is given via the arguments try to get it
	if not titleArg then
		local rootFrame
		local currentFrame = mw.getCurrentFrame()
		while currentFrame ~= nil do
			rootFrame = currentFrame
			currentFrame = currentFrame:getParent()
		end

		titleArg = ':' .. rootFrame:getTitle()
	end

	local title = mw.title.new(mw.text.trim(titleArg), 'Template')
	if not title then
		error('Invalid title ' .. titleArg)
	end

	return title
end

return Class.export(NavBar)
