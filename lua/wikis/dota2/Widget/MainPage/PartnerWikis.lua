---
-- @Liquipedia
-- page=Module:Widget/MainPage/PartnerWikis
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local Link = Lua.import('Module:Widget/Basic/Link')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Html = Lua.import('Module:Widget/Html')
local ListWidgets = Lua.import('Module:Widget/List')

---@class Dota2PartnerWikis: Widget
---@operator call(table): Dota2PartnerWikis
local Dota2PartnerWikis = Class.new(Widget)

---@return Widget
function Dota2PartnerWikis:render()
	---@param props {image: string, link: string, caption: string, description: string}
	---@return Widget
	local function createCellHeader(props)
		return Html.Th{
			attributes = {width = '17%'},
			children = {
				IconImage{
					imageLight = props.image,
					link = props.link,
					size = '60px',
					caption = props.caption,
				},
				Html.Br{},
				Html.Small{
					children = Html.I{children = props.description}
				}
			}
		}
	end

	return DataTable{
		classes = {'wikitable-striped'},
		tableAttributes = {width = '100%'},
		tableCss = {['text-align'] = 'center'},
		children = {
			Html.Tr{children = {
				Html.Th{
					attributes = {
						rowspan = 2,
						width = '15%',
					},
					children = IconImage{
						imageLight = 'Dota 2 Partners VWN.png',
						link = 'Valve Wiki Network',
						size = '100px',
					}
				},
				createCellHeader{
					image = 'Dota 2 Partners VWN Combine OverWiki.png',
					link = 'https://combineoverwiki.net/wiki/Main_Page',
					caption = 'Combine OverWiki',
					description = 'Half-Life / Portal',
				},
				createCellHeader{
					image = 'Dota 2 Partners VWN Left 4 Dead Wiki.png',
					link = 'https://left4deadwiki.com/wiki/Left_4_Dead_Wiki',
					caption = 'Left 4 Dead Wiki',
					description = 'Left 4 Dead',
				},
				createCellHeader{
					image = 'Dota 2 Partners VWN Portal Wiki.png',
					link = 'https://theportalwiki.com/wiki/Main_Page',
					caption = 'Portal Wiki',
					description = 'Portal',
				},
				createCellHeader{
					image = 'Dota 2 Partners VWN Team Fortress 2 Wiki.png',
					link = 'https://wiki.teamfortress.com/wiki/Main_Page',
					caption = 'Official Team Fortress 2 Wiki',
					description = 'Team Fortress 2',
				},
				createCellHeader{
					image = 'Dota 2 default allmode.png',
					link = 'Main Page',
					caption = 'Dota 2 Wiki',
					description = 'Dota 2 Game + E-Sports',
				},
			}},
			Html.Tr{children = {
				Html.Td{children = Link{
					linktype = 'external',
					link = 'https://combineoverwiki.net/wiki/Main_Page',
					children = 'Combine OverWiki',
				}},
				Html.Td{children = Link{
					linktype = 'external',
					link = 'https://left4deadwiki.com/wiki/Left_4_Dead_Wiki',
					children = 'Left 4 Dead Wiki',
				}},
				Html.Td{children = Link{
					linktype = 'external',
					link = 'https://theportalwiki.com/wiki/Main_Page',
					children = 'Portal Wiki',
				}},
				Html.Td{children = Link{
					linktype = 'external',
					link = 'https://wiki.teamfortress.com/wiki/Main_Page',
					children = 'Team Fortress Wiki',
				}},
				Html.Td{children = Link{
					link = 'Main Page',
					children = 'Dota 2 Wiki'
				}}
			}},
			Html.Tr{children = {
				Html.Th{
					children = Link{link = 'Dota 2 Wiki Partners', children = 'Other Partners'}
				},
				Html.Td{
					attributes = {colspan = 5},
					css = {['text-align'] = 'left'},
					children = ListWidgets.Unordered{children = {
						{
							IconImage{
								imageLight = 'Dota 2 Partners IWF.png',
								link = 'https://indiewikifederation.org/',
								caption = 'Indie Wiki Federation',
							},
							' ',
							Link{
								linktype = 'external',
								link = 'https://indiewikifederation.org/',
								children = 'Indie Wiki Federation',
							}
						}
					}}
				}
			}}
		}
	}
end

return Dota2PartnerWikis
