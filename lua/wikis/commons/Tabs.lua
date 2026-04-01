---
-- @Liquipedia
-- page=Module:Tabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local AnalyticsWidgets = Lua.import('Module:Widget/Analytics')
local Button = Lua.import('Module:Widget/Basic/Button')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Tabs = {}
local VALID_VARIANTS = {
	'horizontal',
	'vertical',
	'icon-only',
}

---Creates static tabs.
---Entry point of Template:Tabs static
---@param args table?
---@return Widget?
function Tabs.static(args)
	args = args or {}

	local tabArgs = Tabs._readArguments(args, {allowThis2 = true})
	local tabCount = #tabArgs
	if tabCount == 0 then return end

	Tabs._setThis(tabArgs)

	return AnalyticsWidgets{
		analyticsName = 'Navigation tab',
		children = {
			HtmlWidgets.Div{
				classes = {'tabs-static'},
				attributes = {['data-nosnippet'] = ''},
				children = HtmlWidgets.Ul{
					classes = {'nav', 'nav-tabs', 'navigation-not-searchable', 'tabs', 'tabs' .. tabCount},
					attributes = {['data-nosnippet'] = ''},
					children = Array.map(tabArgs, function (tab)
						--if tab.name is unset tab.link is set as per `Tabs._readArguments`
						local name = tab.name or Tabs._getDisplayNameFromLink(tab.link --[[@as string]])
						local text = tab.link and Page.makeInternalLink({}, name, tab.link) or tab.name
						return HtmlWidgets.Li{
							classes = {tab.this and 'active' or nil},
							children = text
						}
					end)
				}
			},
			HtmlWidgets.Fragment{
				children = Array.map(Array.filter(tabArgs, Operator.property('this')), Operator.property('tabs'))
			}
		}
	}
end

---Creates dynamic tabs.
---Entry point of Template:Tabs dynamic
---@param args table
---@return Widget|string?
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

	if not Array.any(tabArgs, Operator.property('this')) then
		tabArgs[1].this = true
	end

	local variant = args.variant or 'horizontal'
	assert(
		Table.includes(VALID_VARIANTS, variant),
		'Invalid variant "' .. variant .. '". Allowed values are: ' .. table.concat(VALID_VARIANTS, ', ')
	)

	local hasIcon = Array.any(tabArgs, function(tab) return Logic.isNotEmpty(tab.icon) end)
	local allHaveIcon = Array.all(tabArgs, function(tab) return Logic.isNotEmpty(tab.icon) end)

	-- Design decision: mixed icon and non-icon tab toggles are not supported.
	assert(not hasIcon or allHaveIcon, 'If one tab has an icon, all tabs must have icons')
	if variant == 'icon-only' then
		assert(allHaveIcon, 'The "icon-only" variant requires all tabs to have icons')
	end

	local variantClass = 'tabs-variant-' .. variant

	-- Temporary solution for fighters
	local wraps = Logic.readBool(args.wrapping) and Info.wikiName == 'fighters'
	local wrapsClass = wraps and 'wraps' or nil

	local navTabs = HtmlWidgets.Ul{
		classes = {'nav', 'nav-tabs', 'tabs', 'tabs' .. tabCount},
		children = WidgetUtil.collect(
			Array.map(tabArgs, function(tabData, tabIndex)
				return HtmlWidgets.Li{
					classes = {'tab' .. tabIndex, tabData.this and 'active' or nil},
					children = WidgetUtil.collect(
						tabData.icon and Icon{iconName = tabData.icon} or nil,
						HtmlWidgets.Span{children = {tabData.name}}
					)
				}
			end),
			not Logic.nilOr(Logic.readBoolOrNil(args['hide-showall']), isSingular) and HtmlWidgets.Li{
				classes = {'show-all'},
				children = {HtmlWidgets.Span{children = {'Show All'}}}
			} or nil
		)
	}

	local contentChildren = {}

	if hasContent then
		contentChildren = Array.map(tabArgs, function(tabData, tabIndex)
			return HtmlWidgets.Div{
				classes = {'content' .. tabIndex, tabData.this and 'active' or nil},
				attributes = {['data-count'] = tabIndex},
				children = WidgetUtil.collect('\n\n', tabData.content)
			}
		end)
	end

	local contents = Tabs._buildContentDiv(
		hasContent,
		Logic.readBool(args['hybrid-tabs']),
		Logic.readBool(args['no-padding']),
		contentChildren
	)

	local navWrapper = HtmlWidgets.Div{
		classes = {'tabs-nav-wrapper'},
		children = {
			HtmlWidgets.Div{
				classes = {'tabs-scroll-arrow-wrapper', 'tabs-scroll-arrow-wrapper--left'},
				children = {
					Button{
						classes = {'tabs-scroll-arrow', 'tabs-scroll-arrow--left'},
						title = 'Previous',
						variant = 'ghost',
						size = 'md',
						children = {
							HtmlWidgets.Span{
								css = {display = 'inline-flex'},
								children = {Icon{iconName = 'previous', size = 'xs'}}
							},
						},
					}
				}
			},
			navTabs,
			HtmlWidgets.Div{
				classes = {'tabs-scroll-arrow-wrapper', 'tabs-scroll-arrow-wrapper--right'},
				children = {
					Button{
						classes = {'tabs-scroll-arrow', 'tabs-scroll-arrow--right'},
						title = 'Next',
						variant = 'ghost',
						size = 'md',
						children = {
							HtmlWidgets.Span{
								css = {display = 'inline-flex'},
								children = {Icon{iconName = 'next', size = 'xs'}}
							},
						},
					}
				}
			},
		}
	}

	if not hasContent then
		local startTag = '<div class="tabs-dynamic navigation-not-searchable ' .. variantClass ..
			(wraps and ' wraps' or '') .. '" data-nosnippet>\n'
		return startTag .. tostring(navWrapper) .. (contents --[[@as string]])
	end

	return AnalyticsWidgets{
		analyticsName = 'Dynamic Navigation tab',
		css = {width = '-webkit-fill-available'},
		children = HtmlWidgets.Div{
			classes = {'tabs-dynamic', 'navigation-not-searchable', variantClass, wrapsClass},
			attributes = {['data-nosnippet'] = ''},
			children = {
				navWrapper,
				contents
			}
		}
	}
end

---@param args table
---@param options {allowThis2: boolean?, removeEmptyTabs: boolean?}
---@return {name: string?, link: string?, content: string|Html?, tabs: string|Html?, this: boolean, icon: string?}[]
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
				icon = Table.extract(args, 'icon' .. tabIndex),
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
	--   ab/cd/e1
	--   ab/cd/e2
	--   ab/cd/e
	--   ab/cd
	--   ab/cg
	--   ab
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
---@param children table?
---@return Widget|string
function Tabs._buildContentDiv(hasContent, hybridTabs, noPadding, children)
	if hasContent then
		return HtmlWidgets.Div{
			classes = {'tabs-content'},
			css = {
				['border-style'] = hybridTabs and 'none !important' or nil,
				['padding'] = (hybridTabs or noPadding) and '0 !important' or nil,
			},
			children = children
		}
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
---@return Widget
function Tabs._single(tab, showHeader)
	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			showHeader and HtmlWidgets.H6{children = {tab.name}} or nil,
			showHeader and '\n' or nil,
			tab.content
		)
	}
end

---@param link string
---@return string
function Tabs._getDisplayNameFromLink(link)
	local linkParts = mw.text.split(link, '/', true)
	return linkParts[#linkParts]
end

return Class.export(Tabs, {exports = {'static', 'dynamic'}})
