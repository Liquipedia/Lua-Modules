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
local Template = require('Module:Template')

local WikiData = Lua.import('Module:MainPageLayout/data')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local LinkWidget = Lua.import('Module:Widget/Basic/Link')

local MainPageLayout = {}

function MainPageLayout.make(frame)
	local args = Arguments.getArgs(frame)

	local layout = WikiData.layouts[args.layout] or WikiData.layouts.main
	local content = table.concat(MainPageLayout._makeCells(layout))

	return HtmlWidgets.Div{
		classes = {'mainpage-v2'},
		children = {
			Template.expandTemplate(frame, 'Header banner', {
				['logo-lighttheme'] = WikiData.banner.lightmode,
				['logo-darktheme'] = WikiData.banner.darkmode,
			}),
			HtmlWidgets.Div{
				classes = {'navigation-cards'},
				children = Array.map(WikiData.navigation, MainPageLayout._makeNavigationCard)
			},
			content,
		},
	}
end

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
					table.insert(content, Template.safeExpand(frame, 'panel', {
						['body'] = frame:preprocess(item.content.body),
						['box-id'] = item.content.boxid,
						['padding'] = tostring(item.content.padding),
						['heading'] = item.content.heading,
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

---@param navigationData {file: string?, link: string?, count: table?, text: string?}
---@return WidgetHtml
function MainPageLayout._makeNavigationCard(navigationData)
	local count
	if navigationData.count then
		if navigationData.count.method == 'LPDB' then
			count = LpdbCounter.count{table = navigationData.count.table, conditions = navigationData.count.conditions}
		elseif navigationData.count.method == 'CATEGORY' then
			count = mw.getCurrentFrame():preprocess('{{PAGESINCATEGORY:'.. navigationData.count.category .. '}}')
		else
			count = navigationData.count.value
		end
	end

	return HtmlWidgets.Div{
		classes = {'navigation-card'},
		children = {
			HtmlWidgets.Div{
				classes = {'navigation-card__image'},
				children = Image.display(navigationData.file, nil, {size = 240}),
			},
			HtmlWidgets.Span{
				classes = {'navigation-card__title'},
				children = LinkWidget{link = navigationData.link, children = navigationData.text}
			},
			navigationData.count and HtmlWidgets.Span{
				classes = {'navigation-card__subtitle'},
				children = count,
			} or nil,
		}
	}
end

return MainPageLayout
