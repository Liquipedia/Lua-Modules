---
-- This module implements {{Navbox}}
--

local p = {}

local Arguments = require('Module:Arguments')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')

local navbar = require('Module:Navbar')._navbar

local border
local listnums = {}
local ODD_EVEN_MARKER = '\127_ODDEVEN_\127'
local RESTART_MARKER = '\127_ODDEVEN0_\127'
local REGEX_MARKER = '\127_ODDEVEN(%d?)_\127'

local function striped(wikitext)
	-- Return wikitext with markers replaced for odd/even striping.
	-- Child (subgroup) navboxes are flagged with a category that is removed
	-- by parent navboxes. The result is that the category shows all pages
	-- where a child navbox is not contained in a parent navbox.
	local orphanCat = '[[Category:Navbox orphans]]'
	if border == 'subgroup' and not Logic.readBool(args.orphan) then
		-- No change; striping occurs in outermost navbox.
		return wikitext .. orphanCat
	end
	local first, second = 'odd', 'even'
	if args.evenodd then
		if args.evenodd == 'swap' then
			first, second = second, first
		else
			first = args.evenodd
			second = first
		end
	end
	local changer
	if first == second then
		changer = first
	else
		local index = 0
		changer = function (code)
			if code == '0' then
				-- Current occurrence is for a group before a nested table.
				-- Set it to first as a valid although pointless class.
				-- The next occurrence will be the first row after a title
				-- in a subgroup and will also be first.
				index = 0
				return first
			end
			index = index + 1
			return index % 2 == 1 and first or second
		end
	end
	local regex = orphanCat:gsub('([%[%]])', '%%%1')
	return (wikitext:gsub(regex, ''):gsub(REGEX_MARKER, changer))  -- () omits gsub count
end

local function processItem(item, nowrapitems)
	if item:sub(1, 2) == '{|' then
		-- Applying nowrap to lines in a table does not make sense.
		-- Add newlines to compensate for trim of x in |parm=x in a template.
		return '\n' .. item ..'\n'
	end
	if Logic.readBool(nowrapitems) then
		local lines = {}
		for line in (item .. '\n'):gmatch('([^\n]*)\n') do
			local prefix, content = line:match('^([*:;#]+)%s*(.*)')
			if prefix and not content:match('^<span class="nowrap">') then
				line = prefix .. '<span class="nowrap">' .. content .. '</span>'
			end
			table.insert(lines, line)
		end
		item = table.concat(lines, '\n')
	end
	if item:match('^[*:;#]') then
		return '\n' .. item ..'\n'
	end
	return item
end

local function renderNavBar(titleCell)

	if args.navbar ~= 'off' and args.navbar ~= 'plain' and not (not args.name and mw.getCurrentFrame():getParent():getTitle():gsub('/sandbox$', '') == 'Template:Navbox') then
		local fontCssClasses = {}
		if String.isNotEmpty(args.baseclass) then
			table.insert(fontCssClasses, args.baseclass)
		end
		if String.isNotEmpty(args.titleclass) then
			table.insert(fontCssClasses, args.titleclass)
		end
		titleCell:wikitext(navbar{
			args.name,
			mini = 1,
			fontstyle = (args.basestyle or '') .. ';' .. (args.titlestyle or '') .. ';border:none;-moz-box-shadow:none;-webkit-box-shadow:none;box-shadow:none;',
			style = 'float:left; text-align:left',
			fontcssclass = table.concat(fontCssClasses, ' '),
		})
	end

end

--
--   Title row
--
local function renderTitleRow(tbl)
	if not args.title then return end

	local titleRow = tbl:tag('tr')

	if args.titlegroup then
		titleRow
			:tag('th')
				:attr('scope', 'row')
				:addClass('navbox-group')
				:addClass(args.titlegroupclass)
				:addClass(args.groupclass)
				:addClass(args.baseclass)
				:cssText(args.basestyle)
				:cssText(args.groupstyle)
				:cssText(args.titlegroupstyle)
				:wikitext(args.titlegroup)
	end

	local titleCell = titleRow:tag('th'):attr('scope', 'col')

	if args.titlegroup then
		titleCell
			:css('border-left', '2px solid #fdfdfd')
			:css('width', '100%')
	end

	local titleColspan = 2
	if args.imageleft then titleColspan = titleColspan + 1 end
	if args.image then titleColspan = titleColspan + 1 end
	if args.titlegroup then titleColspan = titleColspan - 1 end

	titleCell
		:cssText(args.basestyle)
		:addClass(args.baseclass)
		:addClass(args.titleclass)
		:cssText(args.titlestyle)
		:addClass('navbox-title')
		:attr('colspan', titleColspan)

	renderNavBar(titleCell)

	titleCell
		:tag('div')
			:attr('id', mw.uri.anchorEncode(args.title))
			:addClass(args.titleclass)
			:css('font-size', border == 'subgroup' and '100%' or '114%')
			:css('margin', '0 4em')
			:wikitext(processItem(args.title))
end

--
--   Above/Below rows
--

local function getAboveBelowColspan()
	local ret = 2
	if args.imageleft then ret = ret + 1 end
	if args.image then ret = ret + 1 end
	return ret
end

local function renderAboveRow(tbl)
	if not args.above then return end

	tbl:tag('tr')
		:tag('td')
			:addClass('navbox-abovebelow')
  			:addClass('wiki-backgroundcolor-light')
			:addClass(args.aboveclass)
			:cssText(args.basestyle)
			:addClass(args.baseclass)
			:cssText(args.abovestyle)
			:attr('colspan', getAboveBelowColspan())
			:tag('div')
				:wikitext(processItem(args.above, args.nowrapitems))
end

local function renderBelowRow(tbl)
	if not args.below then return end

	tbl:tag('tr')
		:tag('td')
			:addClass('navbox-abovebelow')
  			:addClass('wiki-backgroundcolor-light')
			:addClass(args.belowclass)
			:cssText(args.basestyle)
			:addClass(args.baseclass)
			:cssText(args.belowstyle)
			:attr('colspan', getAboveBelowColspan())
			:tag('div')
				:wikitext(processItem(args.below, args.nowrapitems))
end

--
--   List rows
--
local function renderListRow(tbl, index, listnum)
	local row = tbl:tag('tr')

	if index == 1 and args.imageleft then
		row
			:tag('td')
				:addClass('navbox-image')
				:addClass(args.imageclass)
				:css('width', '1px')               -- Minimize width
				:css('padding', '0px 2px 0px 0px')
				:cssText(args.imageleftstyle)
				:attr('rowspan', #listnums)
				:tag('div')
					:wikitext(processItem(args.imageleft))
	end

	if args['group' .. listnum] then
		local groupCell = row:tag('th')

		groupCell
			:attr('scope', 'row')
			:addClass('navbox-group')
			:addClass(args.groupclass)
			:addClass(args.baseclass)
			:cssText(args.basestyle)
			:css('width', args.groupwidth or '1%') -- If groupwidth not specified, minimize width

		groupCell
			:cssText(args.groupstyle)
			:addClass(args.groupclass)
			:cssText(args['group' .. listnum .. 'style'])
			:addClass(args['group' .. listnum .. 'class'])
			:wikitext(args['group' .. listnum])
	end

	local listCell = row:tag('td')

	if args['group' .. listnum] then
		listCell:addClass('hlist-group')
	else
		listCell:attr('colspan', 2)
	end

	if not args.groupwidth then
		listCell:css('width', '100%')
	end

	local rowstyle  -- usually nil so cssText(rowstyle) usually adds nothing
	if index % 2 == 1 then
		rowstyle = args.oddstyle
	else
		rowstyle = args.evenstyle
	end

	local listText = args['list' .. listnum]
	local oddEven = ODD_EVEN_MARKER
	if listText:sub(1, 12) == '</div><table' then
		-- Assume list text is for a subgroup navbox so no automatic striping for this row.
		oddEven = listText:find('<th[^>]*"navbox%-title"') and RESTART_MARKER or 'odd'
	end
	listCell
		:css('padding', '0px')
		:cssText(args.liststyle)
		:cssText(rowstyle)
		:cssText(args['list' .. listnum .. 'style'])
		:addClass('navbox-list')
		:addClass('navbox-' .. oddEven)
		:addClass(args.listclass)
		:tag('div')
			:addClass('hlist')
			:css('padding', (index == 1 and args.list1padding) or args.listpadding or '0em 0.25em')
			:wikitext(processItem(listText, args.nowrapitems))

	if index == 1 and args.image then
		row
			:tag('td')
				:addClass('navbox-image')
				:addClass(args.imageclass)
				:css('width', '1px')               -- Minimize width
				:css('padding', '0px 0px 0px 2px')
				:cssText(args.imagestyle)
				:attr('rowspan', #listnums)
				:node(p._makeImage(args.image, args.imagedark))
	end
end


--
--   Tracking categories
--

local function needsHorizontalLists()
	if border == 'subgroup' or args.tracking == 'no' then
		return false
	end
	local listClasses = {
		['plainlist'] = true, ['hlist'] = true, ['hlist hnum'] = true,
		['hlist hwrap'] = true, ['hlist vcard'] = true, ['vcard hlist'] = true,
		['hlist vevent'] = true,
	}
	return not (listClasses[args.listclass] or listClasses[args.bodyclass])
end

local function hasBackgroundColors()
	for _, key in ipairs({'titlestyle', 'groupstyle', 'basestyle'}) do
		if tostring(args[key]):find('background', 1, true) then
			return true
		end
	end
end

local function isIllegible()
	local styleratio = require('Module:Color contrast')._styleratio

	for key, style in pairs(args) do
		if tostring(key):match("style$") then
			if styleratio{mw.text.unstripNoWiki(style)} < 4.5 then
				return true
			end
		end
	end
	return false
end

local function getTrackingCategories()
	local cats = {}
	if needsHorizontalLists() then table.insert(cats, 'Navigational boxes without horizontal lists') end
	if hasBackgroundColors() then table.insert(cats, 'Navboxes using background colours') end
	if isIllegible() then table.insert(cats, 'Potentially illegible navboxes') end
	return cats
end

local function renderTrackingCategories(builder)
	local title = mw.title.getCurrentTitle()
	if title.namespace ~= 10 then return end -- not in template space
	local subpage = title.subpageText
	if subpage == 'doc' or subpage == 'sandbox' or subpage == 'testcases' then return end

	for _, cat in ipairs(getTrackingCategories()) do
		builder:wikitext('[[Category:' .. cat .. ']]')
	end
end

--
--   Main navbox tables
--
local function renderMainTable()
	local tbl = mw.html.create('table')
		:addClass('nowraplinks')
		:addClass(args.bodyclass)

	if args.title and (args.state ~= 'plain' and args.state ~= 'off') then
		tbl
			:addClass('collapsible')
			:addClass(args.state or 'autocollapse')
	end

	tbl:css('border-spacing', 0)
	if border == 'subgroup' or border == 'none' then
		tbl
			:addClass('navbox-subgroup')
			:addClass('wiki-backgroundcolor-light')
			:cssText(args.bodystyle)
			:cssText(args.style)
	else  -- regular navbox - bodystyle and style will be applied to the wrapper table
		tbl
			:addClass('navbox-inner')
			--:css('background', 'transparent')
			--:css('color', 'inherit')
	end
	tbl:cssText(args.innerstyle):addClass(args.innerclass)

	renderTitleRow(tbl)
	renderAboveRow(tbl)
	for i, listnum in ipairs(listnums) do
		renderListRow(tbl, i, listnum)
	end
	renderBelowRow(tbl)

	return tbl
end

function p._navbox(navboxArgs)
	args = navboxArgs

	for k, _ in pairs(args) do
		if type(k) == 'string' then
			local listnum = k:match('^list(%d+)$')
			if listnum then table.insert(listnums, tonumber(listnum)) end
		end
	end
	table.sort(listnums)

	border = mw.text.trim(args.border or args[1] or '')
	if border == 'child' then
		border = 'subgroup'
	end

	-- render the main body of the navbox
	local tbl = renderMainTable()

	-- render the appropriate wrapper around the navbox, depending on the border param
	local res = mw.html.create()
	if border == 'none' then
		local nav = res:tag('div')
			:attr('role', 'navigation')
			:addClass('navigation-not-searchable')
			:attr('data-nosnippet', 0)
			:node(tbl)
		if args.title then
			nav:attr('aria-labelledby', mw.uri.anchorEncode(args.title))
		else
			nav:attr('aria-label', 'Navbox')
		end
	elseif border == 'subgroup' then
		-- We assume that this navbox is being rendered in a list cell of a parent navbox, and is
		-- therefore inside a div with padding:0em 0.25em. We start with a </div> to avoid the
		-- padding being applied, and at the end add a <div> to balance out the parent's </div>
		res
			:wikitext('</div>')
			:node(tbl)
			:wikitext('<div>')
	else
		local nav = res:tag('div')
			:attr('role', 'navigation')
			:addClass('navigation-not-searchable')
			:attr('data-nosnippet', 0)
			:addClass('navbox')
			:cssText(args.bodystyle)
			:cssText(args.style)
			:css('padding', '3px')
			:node(tbl)
		if args.title then
			nav:attr('aria-labelledby', mw.uri.anchorEncode(args.title))
		else
			nav:attr('aria-label', 'Navbox')
		end
	end

	renderTrackingCategories(res)

	return striped(tostring(res))
end

function p.navbox(frame)
	local args = Arguments.getArgs(frame, {wrappers = 'Template:Navbox'})

	-- Read the arguments in the order they'll be output in, to make references number in the right order.
	local _
	_ = args.title
	_ = args.above
	for i = 1, 20 do
		_ = args["group" .. tostring(i)]
		_ = args["list" .. tostring(i)]
	end
	_ = args.below

	return p._navbox(args)
end

function p._makeImage(lightMode, darkMode)
	if not darkMode then
		return mw.html.create('div'):wikitext(processItem(lightMode))
	end

	return mw.html.create()
		:tag('div'):addClass('show-when-light-mode'):wikitext(processItem(lightMode)):done()
		:tag('div'):addClass('show-when-dark-mode'):wikitext(processItem(darkMode)):done()
end

return p
