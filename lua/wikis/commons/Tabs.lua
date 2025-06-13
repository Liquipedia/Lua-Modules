---
-- @Liquipedia
-- page=Module:Tabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Operator = require('Module:Operator')
local Page = require('Module:Page')
local Table = require('Module:Table')

local Tabs = {}

---Creates static tabs.
---Entry point of Template:Tabs static
---@param args table?
---@return Html?
function Tabs.static(args)
	args = args or {}

	local tabArgs = Tabs._readArguments(args, {allowThis2 = true})
	local tabCount = #tabArgs
	if tabCount == 0 then return end

	Tabs._setThis(tabArgs)

	local tabs = mw.html.create('ul')
		:attr('class', 'nav nav-tabs navigation-not-searchable tabs tabs' .. tabCount)
		:attr('data-nosnippet')

	local subTabs = mw.html.create()

	Array.forEach(tabArgs, function(tab)
		--if tab.name is unset tab.link is set as per `Tabs._readArguments`
		local name = tab.name or Tabs._getDisplayNameFromLink(tab.link --[[@as string]])
		local text = tab.link and Page.makeInternalLink({}, name, tab.link) or tab.name
		tabs:tag('li'):addClass(tab.this and 'active' or nil):wikitext(text)
		subTabs:node(tab.this and tab.tabs or nil)
	end)

	return mw.html.create()
		:tag('div')
			:addClass('tabs-static')
			:attr('data-nosnippet', '')
			:node(tabs)
			:done()
		:node(subTabs)
end

---Creates dynamic tabs.
---Entry point of Template:Tabs dynamic
---@param args table
---@return Html|string?
function Tabs.dynamic(args)
	args = args or {}

	local tabArgs = Tabs._readArguments(args, {removeEmptyTabs = Logic.readBool(args.removeEmptyTabs)})
	local tabCount = #tabArgs
	if tabCount == 0 then return end

	local hasContent = Array.all(tabArgs, function(tab)
		return Logic.isNotEmpty(tab.content) end)
	local allEmpty = Array.all(tabArgs, function(tab)
		return Logic.isEmpty(tab.content) end)
	assert(hasContent or allEmpty, 'Some of the tabs have contents while others do not')

	local isSingular = tabCount == 1 and hasContent
	if isSingular and not Logic.readBool(args.showSingularAsTab) then
		return Tabs._single(tabArgs[1], not Logic.readBool(args.suppressHeader))
	end

	local tabs = mw.html.create('ul')
		:addClass('nav nav-tabs tabs tabs' .. tabCount)

	if not Array.any(tabArgs, Operator.property('this')) then
		tabArgs[1].this = true
	end

	---@param obj Html
	---@param elementType string
	---@param content string|Html|?
	---@param class string
	---@param isActive boolean
	local build = function(obj, elementType, content, class, isActive)
		local element = mw.html.create(elementType)
			:addClass(class)
			:addClass(isActive and 'active' or nil)
			:newline()
			:node(content)

		obj:newline():node(element)
	end

	Array.forEach(tabArgs, function(tabData, tabIndex)
		build(tabs, 'li', tabData.name, 'tab' .. tabIndex, tabData.this)
	end)

	if not Logic.nilOr(Logic.readBoolOrNil(args['hide-showall']), isSingular) then
		tabs:tag('li')
			:addClass('show-all')
			:wikitext('Show All')
	end

	tabs:newline()

	local contents = Tabs._buildContentDiv(
		hasContent,
		Logic.readBool(args['hybrid-tabs']),
		Logic.readBool(args['no-padding'])
	)

	if not hasContent then
		return '<div class="tabs-dynamic navigation-not-searchable" data-nosnippet>\n'
			.. tostring(tabs) .. contents
	end
	---@cast contents -string

	Array.forEach(tabArgs, function(tabData, tabIndex)
		build(contents, 'div', tabData.content, 'content' .. tabIndex, tabData.this)
	end)

	return mw.html.create('div')
		:addClass('tabs-dynamic navigation-not-searchable')
		:attr('data-nosnippet')
		:node(tabs)
		:newline()
		:node(contents)
end

---@param args table
---@param options {allowThis2: boolean?, removeEmptyTabs: boolean?}
---@return {name: string?, link: string?, content: string|Html?, tabs: string|Html?, this: boolean}[]
function Tabs._readArguments(args, options)
	local tabArgs = {}
	local tabIndex = 1
	local this = tonumber(args.This)
	local this2 = tonumber(args.This2)

	while args['name' .. tabIndex] or args['link' .. tabIndex] do
		if args['content' .. tabIndex] or not options.removeEmptyTabs then
			table.insert(tabArgs, {
				name = Table.extract(args, 'name' .. tabIndex),
				link = Table.extract(args, 'link' .. tabIndex),
				content = Table.extract(args, 'content' .. tabIndex),
				tabs = Table.extract(args, 'tabs' .. tabIndex),
				this = this == tabIndex or (options.allowThis2 and this2 == tabIndex),
			})
		end
		tabIndex = tabIndex + 1
	end

	if Logic.readBool(args.returnIfEmpty) then
		return tabArgs
	end

	assert(Logic.isNotEmpty(tabArgs), 'You are trying to add a "Tabs" template without arguments for names nor links')

	return tabArgs
end

---@param tabArgs {name: string?, link: string?, content: string|Html?, tabs: string|Html?, this: boolean}[]
function Tabs._setThis(tabArgs)
	if Array.any(tabArgs, Operator.property('this')) then return end

	local fullPageName = mw.title.getCurrentTitle().prefixedText
	local this

	-- Finds the link that is a prefix of the current page. If there are more than one, choose the longest, then first.
	-- For example, if the current page is ab/cd/e3, then among
	--   ab/cd/e1
	--   ab/cd/e2
	--   ab/cd/e
	--   ab/cd
	--   ab/cg
	--   ab
	-- it will pick ab/cd.
	local maxLinkLength = -1

	Array.forEach(tabArgs, function (tab, tabIndex)
		local link = tab.link
		if not link then return end
		link = link:gsub('_', ' ')
		local linkLength = string.len(link)
		local charAfter = string.sub(fullPageName, linkLength + 1, linkLength + 1)
		local pagePartial = string.sub(fullPageName, 1, linkLength)
		if pagePartial == link and (charAfter == '/' or charAfter == '') and linkLength > maxLinkLength then
			maxLinkLength = linkLength
			this = tabIndex
		end
	end)

	if not this then return end

	tabArgs[this].this = true
end

---@param hasContent boolean
---@param hybridTabs boolean
---@param noPadding boolean
---@return Html|string
function Tabs._buildContentDiv(hasContent, hybridTabs, noPadding)
	if hasContent then
		local contentDiv = mw.html.create('div')
			:addClass('tabs-content')
		if hybridTabs then
			contentDiv
				:css('border-style', 'none !important')
				:css('padding', '0 !important')
		elseif noPadding then
			contentDiv
				:css('padding', '0 !important')
		end
		return contentDiv
	end

	local style = ''
	if hybridTabs then
		style = 'border-style:none !important; padding:0 !important;'
	elseif noPadding then
		style = 'padding:0 !important;'
	end
	return '\n<div class="tabs-content" style="' .. style .. '">'
end

---@param tab {name: string?, link: string?, content: string|Html?, tabs: string|Html?, this: boolean}
---@param showHeader boolean
---@return Html
function Tabs._single(tab, showHeader)
	local header
	if showHeader then
		header = mw.html.create()
			:tag('h6'):wikitext(tab.name):done()
			:newline()
	end
	return mw.html.create()
		:node(header)
		:node(tab.content)
end

---@param link string
---@return string
function Tabs._getDisplayNameFromLink(link)
	local linkParts = mw.text.split(link, '/', true)
	return linkParts[#linkParts]
end

return Class.export(Tabs, {exports = {'static', 'dynamic'}})
