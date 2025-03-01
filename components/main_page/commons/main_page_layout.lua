---
-- @Liquipedia
-- wiki=commons
-- page=Module:MainPageLayout
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Grid = require('Module:Grid')
local Image = require('Module:Image')
local LpdbCounter = require('Module:LPDB entity count')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local WikiData = Lua.import('Module:MainPageLayout/data')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local LinkWidget = Lua.import('Module:Widget/Basic/Link')
local PanelWidget = Lua.import('Module:Widget/Panel')

local MainPageLayout = {}

local NO_TABLE_OF_CONTENTS = '__NOTOC__'
local METADESC = '<metadesc>${metadesc}</metadesc>'

---@param frame Frame
---@return WidgetHtml
function MainPageLayout.make(frame)
	assert(WikiData.banner, 'MainPageLayout: Banner data not found')
	assert(WikiData.layouts, 'MainPageLayout: Layout data not found')
	assert(WikiData.navigation, 'MainPageLayout: Navigation data not found')
	assert(WikiData.metadesc, 'MainPageLayout: Metadesc data not found')
	assert(WikiData.title, 'MainPageLayout: Title data not found')

	local args = Arguments.getArgs(frame)
	local layout = WikiData.layouts[args.layout] or WikiData.layouts.main

	return HtmlWidgets.Div{
		classes = {'mainpage-v2'},
		children = {
			NO_TABLE_OF_CONTENTS,
			frame:preprocess(String.interpolate(METADESC, {metadesc = WikiData.metadesc})),
			frame:preprocess('{{DISPLAYTITLE:' .. WikiData.title .. '}}'),
			Template.expandTemplate(frame, 'Header banner', {
				['logo-lighttheme'] = WikiData.banner.lightmode,
				['logo-darktheme'] = WikiData.banner.darkmode,
			}),
			HtmlWidgets.Div{
				classes = {'navigation-cards'},
				children = Array.map(WikiData.navigation, MainPageLayout._makeNavigationCard)
			},
			table.concat(MainPageLayout._makeCells(layout)),
		},
	}
end

---@param cells table[]
---@return string[]
function MainPageLayout._makeCells(cells)
	local frame = mw.getCurrentFrame()
	local output = {}

	table.insert(output, Grid._start_grid{})
	for _, column in ipairs(cells) do
		local cellContent = {}
		for _, item in ipairs(column.children) do
			local content = {}
			if item.content then
				if item.content.noPanel then
					table.insert(content, frame:preprocess(item.content.body))
				else
					local contentBody = item.content.body
					table.insert(content, tostring(PanelWidget{
						body = type(contentBody) == 'string' and frame:preprocess(contentBody) or contentBody,
						boxId = item.content.boxid,
						padding = item.content.padding,
						heading = item.content.heading,
						panelAttributes = item.content.panelAttributes,
					}))
				end
			end
			if item.children then
				Array.extendWith(content, MainPageLayout._makeCells(item.children))
			end
			table.insert(cellContent, tostring(Grid._cell{table.concat(content), ['order-xs'] = item.mobileOrder}))
		end
		table.insert(output, tostring(Grid._cell{table.concat(cellContent), lg = column.size, xs = 'ignore', sm = 'ignore'}))
	end
	table.insert(output, Grid._end_grid{})
	return output
end

---@param navigationData {file: string?, link: string?, count: table?, title: string?}
---@return WidgetHtml
function MainPageLayout._makeNavigationCard(navigationData)
	local count
	if navigationData.count then
		if navigationData.count.method == 'LPDB' then
			count = LpdbCounter.count{table = navigationData.count.table, conditions = navigationData.count.conditions}
		elseif navigationData.count.method == 'CATEGORY' then
			count = mw.site.stats.pagesInCategory(navigationData.count.category, 'pages')
		else
			count = navigationData.count.value
		end
	end

	return HtmlWidgets.Div{
		classes = {'navigation-card'},
		children = {
			HtmlWidgets.Div{
				classes = {'navigation-card__image'},
				children = Image.display(navigationData.file, nil, {size = 240, link = ''}),
			},
			HtmlWidgets.Span{
				classes = {'navigation-card__title'},
				children = LinkWidget{link = navigationData.link, children = navigationData.title}
			},
			count and HtmlWidgets.Span{
				classes = {'navigation-card__subtitle'},
				children = count,
			} or nil,
		}
	}
end

return MainPageLayout
