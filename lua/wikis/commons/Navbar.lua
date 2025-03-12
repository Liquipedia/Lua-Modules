---

local p = {}

local Arguments = require('Module:Arguments')

function p._navbar(args)
	local titleArg = 1

	if args.collapsible then
		titleArg = 2
		if not args.plain then
			args.mini = 1
		end
		args.style = 'float:left; text-align:left'
	end

	local titleText = args[titleArg] or (':' .. mw.getCurrentFrame():getParent():getTitle())
	local title = mw.title.new(mw.text.trim(titleText), 'Template');

	if not title then
		error('Invalid title ' .. titleText)
	end

	local talkpage = title.talkPageTitle and title.talkPageTitle.fullText or '';

	local div = mw.html.create():tag('div')
	div
		:addClass('noprint')
		:addClass('plainlinks')
		:addClass('navbox-navbar')
		--:css('background', 'none')
		:css('padding', '0')
		:css('font-size', 'xx-small')
		:cssText(args.style)

	if args.mini then div:addClass('mini') end

	if not (args.mini or args.plain) then
		div
			:tag('span')
				:css('word-spacing', 0)
				:cssText(args.fontstyle)
				:addClass(args.fontcssclass)
				:wikitext(args.text or 'This box:')
				:wikitext(' ')
	end

	if args.brackets then
		div
			:tag('span')
				:css('margin-right', '-0.125em')
				:cssText(args.fontstyle)
				:addClass(args.fontcssclass)
				:wikitext('&#91; ')
	end

	local ul = div:tag('ul');

	ul
		:addClass('hlist')
		:tag('li')
			:addClass('nv-view')
			:wikitext('[[' .. title.fullText .. '|')
			:tag(args.mini and 'abbr' or 'span')
				:attr('title', 'View this template')
				:cssText(args.fontstyle)
				:addClass(args.fontcssclass)
				:wikitext(args.mini and 'v' or 'view')
				:done()
			:wikitext(']]')
			:done()
		:tag('li')
			:addClass('nv-talk')
			:wikitext('[[' .. talkpage .. '|')
			:tag(args.mini and 'abbr' or 'span')
				:attr('title', 'Discuss this template')
				:cssText(args.fontstyle)
				:addClass(args.fontcssclass)
				:wikitext(args.mini and 'd' or 'talk')
				:done()
			:wikitext(']]');

	if not args.noedit then
		ul
			:tag('li')
				:addClass('nv-edit')
				:wikitext('[' .. title:fullUrl('action=edit') .. ' ')
				:tag(args.mini and 'abbr' or 'span')
					:attr('title', 'Edit this template')
					:cssText(args.fontstyle)
					:addClass(args.fontcssclass)
					:wikitext(args.mini and 'e' or 'edit')
					:done()
				:wikitext(']');
	end

	if args.brackets then
		div
			:tag('span')
				:css('margin-left', '-0.125em')
				:cssText(args.fontstyle)
				:addClass(args.fontcssclass)
				:wikitext(' &#93;')
	end

	if args.collapsible then
		div
			:done()
		:tag('div')
			:css('font-size', '114%')
			:css('margin', args.mini and '0 4em' or '0 7em')
			:cssText(args.fontstyle)
			:addClass(args.fontcssclass)
			:wikitext(args[1])
	end

	return tostring(div:done())
end

function p.navbar(frame)
	return p._navbar(Arguments.getArgs(frame))
end

return p
