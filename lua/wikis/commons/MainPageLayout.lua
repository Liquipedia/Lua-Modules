---
-- @Liquipedia
-- page=Module:MainPageLayout
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Image = Lua.import('Module:Image')
local LpdbCounter = Lua.import('Module:LPDB entity count')
local String = Lua.import('Module:StringUtils')

local WikiData = Lua.import('Module:MainPageLayout/data')
local GridWidgets = Lua.import('Module:Widget/Grid')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local NavigationCard = Lua.import('Module:Widget/MainPage/NavigationCard')
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
			HtmlWidgets.Div{
				classes = {'navigation-cards'},
				children = Array.map(WikiData.navigation, MainPageLayout._makeNavigationCard)
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

	for _, column in ipairs(cells) do
		local cellContent = {}
		for _, item in ipairs(column.children) do
			local content = {}
			if item.content then
				local contentBody = item.content.body
				if item.content.noPanel then
					table.insert(content, MainPageLayout._processCellBody(contentBody))
				else
					table.insert(content, PanelWidget{
						children = MainPageLayout._processCellBody(contentBody),
						boxId = item.content.boxid,
						padding = item.content.padding,
						heading = item.content.heading,
						panelAttributes = item.content.panelAttributes,
					})
				end
			end
			if item.children then
				Array.appendWith(content, MainPageLayout._makeCells(item.children))
			end
			table.insert(cellContent, GridWidgets.Cell{cellContent = content, ['order-xs'] = item.mobileOrder})
		end
		table.insert(output, GridWidgets.Cell{cellContent = cellContent, lg = column.size, xs = 'ignore', sm = 'ignore'})
	end

	return GridWidgets.Container{ gridCells = output }
end

---@param navigationData {file: string?, link: string?, count: table?, title: string?}
---@return Widget
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

	return NavigationCard{
		file = navigationData.file,
		link = navigationData.link,
		title = navigationData.title,
		count = count
	}
end

return MainPageLayout
