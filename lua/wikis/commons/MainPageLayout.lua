---
-- @Liquipedia
-- page=Module:MainPageLayout
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Count = Lua.import('Module:Count')
local Image = Lua.import('Module:Image')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local AnalyticsMapping = Lua.import('Module:MainPageLayout/AnalyticsMapping', {loadData = true})
local WikiData = Lua.import('Module:MainPageLayout/data')
local GridWidgets = Lua.import('Module:Widget/Grid')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local NavigationCard = Lua.import('Module:Widget/MainPage/NavigationCard')
local PanelWidget = Lua.import('Module:Widget/Panel')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')

local MainPageLayout = {}

local NO_TABLE_OF_CONTENTS = '__NOTOC__'

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
			mw.ext.SearchEngineOptimization.metadesc(WikiData.metadesc),
			frame:callParserFunction('DISPLAYTITLE', WikiData.title),
			HtmlWidgets.Div{
				classes = {'header-banner'},
				children = {
					HtmlWidgets.Div{
						classes = {'header-banner__logo'},
						children = {
							HtmlWidgets.Div{
								classes = {'logo--light-theme'},
								children = { Image.display(WikiData.banner.lightmode, nil, {size = 200, link = ''}) }
							},
							HtmlWidgets.Div{
								classes = {'logo--dark-theme'},
								children = { Image.display(WikiData.banner.darkmode, nil, {size = 200, link = ''}) }
							}
						},
					},
					frame:callParserFunction('#searchbox', ''),
				}
			},
			AnalyticsWidget{
				analyticsName = 'Quick navigation',
				children = {
					HtmlWidgets.Div{
						classes = {'navigation-cards'},
						children = Array.map(WikiData.navigation, MainPageLayout._makeNavigationCard)
					}
				}
			},
			MainPageLayout._makeCells(layout),
		},
	}
end

---@param body (string|Widget|Html|nil)|(string|Widget|Html|nil)[]
---@return (string|Widget|Html|nil)|(string|Widget|Html|nil)[]
function MainPageLayout._processCellBody(body)
	local frame = mw.getCurrentFrame()
	return type(body) == 'string' and frame:preprocess(body) or body
end

---@param cells table[]
---@return Widget
function MainPageLayout._makeCells(cells)
	local output = {}
	local desktopBreakpoints = {'lg', 'xl', 'xxl', 'xxxl'}

	for _, column in ipairs(cells) do
		local cellContent = {}
		for _, item in ipairs(column.children) do
			local content = {}
			if item.content then
				local contentBody = item.content.body
				local contentElement
				if item.content.noPanel then
					contentElement = MainPageLayout._processCellBody(contentBody)
				else
					contentElement = PanelWidget{
						children = MainPageLayout._processCellBody(contentBody),
						boxId = item.content.boxid,
						padding = item.content.padding,
						heading = item.content.heading,
						panelAttributes = item.content.panelAttributes,
					}
				end

				table.insert(content, AnalyticsWidget{
					analyticsName = AnalyticsMapping[item.content.boxid],
					children = {contentElement}
				})
			end
			if item.children then
				Array.appendWith(content, MainPageLayout._makeCells(item.children))
			end
			table.insert(cellContent, GridWidgets.Cell{
				cellContent = content,
				['order-xs'] = item.mobileOrder,
				['order-sm'] = item.mobileOrder
			})
		end

		local columnSizes = {}
		if column.size then
			columnSizes = Table.map(desktopBreakpoints, function(_, bp) return bp, column.size end)
		end
		if column.sizes then
			columnSizes = Table.merge(columnSizes, column.sizes)
		end

		local cellProps = Table.merge(
			{cellContent = cellContent, xs = 'ignore', sm = 'ignore'},
			columnSizes
		)
		table.insert(output, GridWidgets.Cell(cellProps))
	end

	return GridWidgets.Container{ gridCells = output }
end

---@param navigationData {file: string?, iconName: string?, link: string?, count: table?, title: string?}
---@return Widget
function MainPageLayout._makeNavigationCard(navigationData)
	local count
	if navigationData.count then
		if navigationData.count.method == 'LPDB' then
			count = Count.query(navigationData.count.table, navigationData.count.conditions or '')
		elseif navigationData.count.method == 'CATEGORY' then
			count = mw.site.stats.pagesInCategory(navigationData.count.category, 'pages')
		else
			count = navigationData.count.value
		end
	end

	return NavigationCard{
		file = navigationData.file,
		iconName = navigationData.iconName,
		link = navigationData.link,
		title = navigationData.title,
		count = count
	}
end

return MainPageLayout
