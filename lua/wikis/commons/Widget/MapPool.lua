---
-- @Liquipedia
-- page=Module:Widget/MapPool
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Map = Lua.import('Module:Map')
local MapModes = Lua.import('Module:MapModes')

local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MapPool: Widget
---@operator call(table?): MapPool
local MapPool = Class.new(Widget)

---@return Widget
function MapPool:render()
	return Div{
		children = GeneralCollapsible{
			title = 'Map Pool',
			classes = {'wiki-backgroundcolor-light'},
			css = {
				display = 'flex',
				['flex-direction'] = 'column',
				padding = '0.5rem',
				['border-radius'] = '0.5rem',
			},
			shouldCollapse = true,
			children = {
				Div{
					css = {
						display = 'flex',
						['flex-wrap'] = 'wrap',
						gap = '0.5rem',
						['padding-top'] = '0.5rem',
					},
					children = Array.mapIndexes(function (index)
						local mode = self.props['mode' .. index]
						if Logic.isEmpty(mode) then
							return
						end
						return self:_renderMapsInMode(mode, Array.parseCommaSeparatedString(self.props['map' .. index]))
					end)
				}
			}
		}
	}
end

---@private
---@param mode string
---@param mapInput string[]
---@return Widget
function MapPool:_renderMapsInMode(mode, mapInput)
	return HtmlWidgets.Table{
		classes = {'wikitable', 'wikitable-striped'},
		css = {
			['border-radius'] = '0.5rem',
			overflow = 'hidden',
			flex = '1 0 18%',
			['white-space'] = 'nowrap'
		},
		children = WidgetUtil.collect(
			HtmlWidgets.Tr{children = HtmlWidgets.Th{
				css = {
					height = '2.5rem',
					padding = '0.2em 0.5rem'
				},
				children = {
					MapModes.get{mode = mode},
					'&nbsp;',
					Link{link = mode}
				}
			}},
			Array.map(mapInput, function (mapPage)
				local map = Map.getMapByPageName(mapPage) or {}
				return HtmlWidgets.Tr{children = HtmlWidgets.Td{
					css = {
						['text-align'] = 'center',
						padding = '0.2em 0.5rem'
					},
					children = {
						Link{
							link = map.pageName or mapPage,
							children = map.displayName or mapPage
						}
					}
				}}
			end)
		)
	}
end

return MapPool
