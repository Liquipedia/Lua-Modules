-- Original source copied from Wikipedia on 2017-12-20.
-- Modified (code style + using Class Module) on 2021-12-?? for liquipedia

local NavBar = require('Module:Navbar')
local Class = require('Module:Class')
local String = require('Module:StringUtils')

local NavBox = {}

local _args
local _border

--legacy entry points
function NavBox.navbox(args, border)
	return NavBox.NavBox(args, border)
end
function NavBox._navbox(args, border)
	return NavBox.NavBox(args, border)
end

function NavBox.NavBox(args, border)
	_args = args or {}
	_border = _args.border or border
	if _border == 'child' then
		_border = 'subgroup'
	end

	local body = NavBox._renderBody()

	local wrapper = NavBox._wrapper(body)

	wrapper = NavBox._addTrackingCategories(wrapper)
	return NavBox._striped(tostring(wrapper))
end

---
-- Display Components
--
function NavBox._wrapper(body)
	local wrapper = mw.html.create()
	if _border == 'none' then
		local navDiv = wrapper:tag('div')
			:attr('role', 'navigation')
			:node(body)

		if _args.title then
			navDiv:attr('aria-labelledby', mw.uri.anchorEncode(_args.title))
		else
			navDiv:attr('aria-label', 'Navbox')
		end
	elseif _border == 'subgroup' then
		-- Since this is a subgroup of a navbox this navbox is being rendered in a parent navbox
		-- due to that this navbox is inside a div with padding
		-- to circumvenbt this we close the div first before we add another div without the padding
		-- at the end we need to add another div to balance out the </div> coming from the parent
		wrapper:wikitext('</div>')
			:node(body)
			:wikitext('<div>')
	else
		local navDiv = wrapper:tag('div')
			:addClass('navbox')
			:attr('role', 'navigation')
			:css('padding', '3px')
			:cssText(_args.bodystyle)
			:cssText(_args.style)
			:node(body)

		if _args.title then
			navDiv:attr('aria-labelledby', mw.uri.anchorEncode(_args.title))
		else
			navDiv:attr('aria-label', 'Navbox')
		end
	end

	return wrapper
end

function NavBox._renderBody()
	local body = mw.html.create('table')
		:addClass('nowraplinks')
		:addClass(_args.bodyclass)

	if _args.title and (_args.state ~= 'plain' and _args.state ~= 'off') then
		body
			:addClass('collapsible')
			:addClass(_args.state or 'autocollapse')
	end

	body:css('border-spacing', 0)

	if _border == 'subgroup' or _border == 'none' then
		body
			:addClass('navbox-subgroup')
			:addClass('wiki-backgroundcolor-light')
			:cssText(_args.bodystyle)
			:cssText(_args.style)
	else -- normal navbox - bodystyle and style will be applied to the wrapper
		body:addClass('navbox-inner')
	end

	body:cssText(_args.innerstyle)

	body = NavBox._titleRow(body)
	body = NavBox._aboveBelowRow(body, 'above')

	--Option 1: alllow gaps in the listIndexes (current implementation)
	local listIndices = {}
	for key, _ in pairs(_args) do
		if type(key) == 'string' then
			local listIndex = key:match('^list(%d+)$')
			if listIndex then
				table.insert(listIndices, tonumber(listIndex))
			end
		end
	end
	table.sort(listIndices)

	local numberOfLists = #listIndices
	for key, listIndex in ipairs(listIndices) do
		body = NavBox._listRow(
			body,
			_args['list' .. listIndex],
			listIndex,
			numberOfLists,
			key == 1,
			key
		)
	end

	--[[Option 2: Only take continues listIndexes (change to the current implementation)
	local listIndex = 1
	local list = agrs['list' .. listIndex]
	local lists = {}
	while String.isNotEmpty(list) do
		table.insert(lists, list)
		listIndex = listIndex + 1
		list = agrs['list' .. listIndex]
	end

	local numberOfLists = #lists
	for index, list in ipairs(lists) do
		body = NavBox._listRow(
			body,
			list,
			index,
			numberOfLists,
			index == 1,
			index
		)
	end
	]]--

	body = NavBox._aboveBelowRow(body, 'below')

	return body
end

function NavBox._titleRow(body)
	if String.isEmpty(_args.title) then
		return body
	end

	local titleRow = body:tag('tr')

	if _args.titlegroup then
		titleRow:tag('th')
			:attr('scope', 'row')
			:addClass('navbox-group')
			:addClass('wiki-backgroundcolor-light')
			:addClass(_args.titlegroupclass)
			:cssText(_args.basestyle)
			:cssText(_args.groupstyle)
			:cssText(_args.titlegroupstyle)
			:wikitext(_args.titlegroup)
	end

	local titleCell = titleRow:tag('th'):attr('scope', 'col')

	if _args.titlegroup then
		titleCell
			:css('border-left', '2px solid #fdfdfd')
			:css('width', '100%')
	end

	local titleColspan = 2
	if _args.imageleft then titleColspan = titleColspan + 1 end
	if _args.image then titleColspan = titleColspan + 1 end
	if _args.titlegroup then titleColspan = titleColspan - 1 end

	titleCell
		:cssText(_args.basestyle)
		:cssText(_args.titlestyle)
		:addClass('navbox-title')
		:addClass('wiki-backgroundcolor-light')
		:attr('colspan', titleColspan)

	titleCell = NavBox._renderNavBar(titleCell)

	titleCell
		:tag('div')
			:attr('id', mw.uri.anchorEncode(_args.title))
			:addClass(_args.titleclass)
			:css('font-size', '114%')
			:css('margin', '0 4em')
			:wikitext(NavBox._processItem(_args.title))

	return body
end

function NavBox._renderNavBar(titleCell)
	if
		_args.navbar ~= 'off'
		and _args.navbar ~= 'plain'
		and (
			String.isNotEmpty(_args.name) or
			NavBox._isNotNavboxTemplate()
		)
	then
		titleCell:wikitext(NavBar.NavBar(
			{
				mini = 1,
				fontstyle = (_args.basestyle or '') .. ';'
					.. (_args.titlestyle or '') .. ';'
					.. 'border:none;'
					.. '-moz-box-shadow:none;'
					.. '-webkit-box-shadow:none;'
					.. 'box-shadow:none;',
				style = 'float:left;'
					.. 'text-align:left'
			},
			_args.name
		))
	end

	return titleCell
end

-- checks if the template being used to display the navbox
-- is the (main) Navbox template or its sandbox
function NavBox._isNotNavboxTemplate()
	return mw.getCurrentFrame():getParent():getTitle():gsub('/sandbox$', '') ~= 'Template:Navbox'
end

function NavBox._aboveBelowRow(body, rowType)
	if String.isEmpty(_args[rowType]) then
		return body
	end

	body:tag('tr')
			:tag('td')
				:addClass('navbox-abovebelow')
				:addClass('wiki-backgroundcolor-light')
				:addClass(_args[rowType .. 'class'])
				:cssText(_args.basestyle)
				:cssText(_args[rowType .. 'style'])
				:attr('colspan', NavBox._getAboveBelowColspan())
				:tag('div')
					:wikitext(NavBox._processItem(_args[rowType], _args.nowrapitems))

	return body
end

function NavBox._getAboveBelowColspan()
	local colSpan = 2
	if _args.imageleft then
		colSpan = colSpan + 1
	end
	if _args.image then
		colSpan = colSpan + 1
	end
	return colSpan
end

function NavBox._processItem(item, noWrapItems)
	if item:sub(1, 2) == '{|' then
		return '\n' .. item ..'\n'
	end

	if noWrapItems == 'yes' then
		local lines = {}
		-- splits the list (as wiki text) given in the
		-- list parameter (= item in this case) into lines
		for line in (item .. '\n'):gmatch('([^\n]*)\n') do
			-- splits the line into its prefix (`*` or `#`) and its content
			local prefix, content = line:match('^([*:;#]+)%s*(.*)')
			-- if the prefix is non empty and the content doesn't start with a nowrap span then ...
			if prefix and not content:match('^<span class="nowrap">') then
				line = prefix .. '<span class="nowrap">' .. content .. '</span>'
			end
			table.insert(lines, line)
		end
		item = table.concat(lines, '\n')
	end

	-- if the item starts with a `*` or `#` (i.e. is a list) then ...
	if item:match('^[*:;#]') then
		return '\n' .. item ..'\n'
	end

	return item
end

local _ODD_EVEN_MARKER = '\127_ODDEVEN_\127'
local _RESTART_MARKER = '\127_ODDEVEN0_\127'

function NavBox._listRow(body, listText, listIndex, numberOfLists, isFirstList, index)
	local row = body:tag('tr')

	if isFirstList and String.isNotEmpty(_args.imageleft) then
		row:tag('td')
			:addClass('navbox-image')
			:addClass(_args.imageclass)
			:css('width', '1px') -- Minimize width
			:css('padding', '0px 2px 0px 0px')
			:cssText(_args.imageleftstyle)
			:attr('rowspan', numberOfLists)
			:tag('div')
				:wikitext(NavBox._processItem(_args.imageleft))
	end

	if String.isNotEmpty(_args['group' .. listIndex]) then
		row:tag('th')
			:attr('scope', 'row')
			:addClass('navbox-group')
			:addClass('wiki-backgroundcolor-light')
			:addClass(_args.groupclass)
			:cssText(_args.basestyle)
			:css('width', _args.groupwidth or '1%') -- If groupwidth not specified, minimize width
			:cssText(_args.groupstyle)
			:cssText(_args['group' .. listIndex .. 'style'])
			:wikitext(_args['group' .. listIndex])
	end

	local listCell = row:tag('td')

	if String.isNotEmpty(_args['group' .. listIndex]) then
		listCell:addClass('hlist-group')
	else
		listCell:attr('colspan', 2)
	end

	if String.isEmpty(_args.groupwidth) then
		listCell:css('width', '100%')
	end

	local rowStyle -- usually nil so cssText(rowStyle) usually adds nothing
	if index % 2 == 1 then
		rowStyle = _args.oddstyle
	else
		rowStyle = _args.evenstyle
	end

	local oddEven = _ODD_EVEN_MARKER
	if listText:sub(1, 12) == '</div><table' then
		-- Assume list text is for a subgroup navbox so no automatic striping for this row.
		oddEven = listText:find('<th[^>]*"navbox%-title"') and _RESTART_MARKER or 'odd'
	end

	listCell
		:css('padding', '0px')
		:cssText(_args.liststyle)
		:cssText(rowStyle)
		:cssText(_args['list' .. listIndex .. 'style'])
		:addClass('navbox-list')
		:addClass('navbox-' .. oddEven)
		:addClass(_args.listclass)
		:tag('div')
			:css('padding', (index == 1 and _args.list1padding) or _args.listpadding or '0em 0.25em')
			:wikitext(NavBox._processItem(listText, _args.nowrapitems))

	if isFirstList and String.isNotEmpty(_args.image) then
		row:tag('td')
			:addClass('navbox-image')
			:addClass(_args.imageclass)
			:css('width', '1px') -- Minimize width
			:css('padding', '0px 0px 0px 2px')
			:cssText(_args.imagestyle)
			:attr('rowspan', numberOfLists)
			:tag('div')
				:wikitext(NavBox._processItem(_args.image))
	end

	return body
end

local _REGEX_MARKER = '\127_ODDEVEN(%d?)_\127'

function NavBox._striped(wikiText)
	-- Return wikiText with markers replaced for odd/even striping.
	-- Child (subgroup) navboxes are flagged with a category that is removed
	-- by parent navboxes. The result is that the category shows all pages
	-- where a child navbox is not contained in a parent navbox.
	local orphanCategory = '[[Category:Navbox orphans]]'
	if _border == 'subgroup' and _args.orphan ~= 'yes' then
		-- No change; striping occurs in outermost navbox.
		return wikiText .. orphanCategory
	end
	local first, second = 'odd', 'even'
	if _args.evenodd then
		if _args.evenodd == 'swap' then
			first, second = second, first
		else
			first = _args.evenodd
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
	local regex = orphanCategory:gsub('([%[%]])', '%%%1')
	wikiText = wikiText:gsub(regex, '')
	wikiText = wikiText:gsub(_REGEX_MARKER, changer)
	return wikiText
end

---
-- Tracking categories
--
local _TEMPLATE_NAMESPACE_NUMBER = 10
function NavBox._addTrackingCategories(wrapper)
	local title = mw.title.getCurrentTitle()
	if title.namespace ~= _TEMPLATE_NAMESPACE_NUMBER then
		return wrapper
	end

	local subpage = title.subpageText
	if
		subpage == 'doc' or
		subpage == 'sandbox' or
		subpage == 'testcases'
	then
		return wrapper
	end

	for _, category in pairs(NavBox._getTrackingCategories()) do
		wrapper:wikitext('[[Category:' .. category .. ']]')
	end

	return wrapper
end

function NavBox._getTrackingCategories()
	local categories = {}

	if NavBox._needsHorizontalLists() then
		table.insert(categories, 'Navigational boxes without horizontal lists')
	end
	if NavBox._hasBackgroundColors() then
		table.insert(categories, 'Navboxes using background colours')
	end
	if NavBox._isIllegible() then
		table.insert(categories, 'Potentially illegible navboxes')
	end

	return categories
end

function NavBox._needsHorizontalLists()
	if _border == 'subgroup' or _args.tracking == 'no' then
		return false
	end
	local listClasses = {
		['plainlist'] = true, ['hlist'] = true, ['hlist hnum'] = true,
		['hlist hwrap'] = true, ['hlist vcard'] = true, ['vcard hlist'] = true,
		['hlist vevent'] = true,
	}
	return not (listClasses[_args.listclass] or listClasses[_args.bodyclass])
end

function NavBox._hasBackgroundColors()
	for _, key in ipairs({'titlestyle', 'groupstyle', 'basestyle'}) do
		if tostring(_args[key]):find('background', 1, true) then
			return true
		end
	end
end

function NavBox._isIllegible()
	local styleratio = require('Module:Color contrast')._styleratio

	for key, style in pairs(_args) do
		if tostring(key):match("style$") then
			if styleratio{mw.text.unstripNoWiki(style)} < 4.5 then
				return true
			end
		end
	end
	return false
end

return Class.export(NavBox)
