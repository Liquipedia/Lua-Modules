---
-- @Liquipedia
-- page=Module:Widget/CharacterStats/DetailsPopup/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class CharacterStatsDetailsPopupContainer: Widget
---@operator call(table): CharacterStatsDetailsPopupContainer
local CharacterStatsDetailsPopupContainer = Class.new(Widget)

---@return Widget?
function CharacterStatsDetailsPopupContainer:render()
	if Logic.isEmpty(self.props.children) then
		return
	end
	return HtmlWidgets.Div{
		classes = {'tabs-dynamic'},
		css = {width = '55px'},
		children = {
			HtmlWidgets.Ul{
				classes = {'nav', 'nav-tabs'},
				css = {border = 'none', display = 'contents'},
				children = Array.map({'show', 'x'}, function (label)
					return HtmlWidgets.Li{
						classes = {'character-stats-popup-button'},
						css = {width = (string.len(label) * 7 + 8) .. 'px'},
						children = HtmlWidgets.Div{
							css = {
								position = 'absolute',
								['margin-top'] = '-7px',
								['margin-left'] = '-6px',
							},
							children = label
						}
					}
				end)
			},
			HtmlWidgets.Div{
				classes = {'tabs-content'},
				css = {
					border = 'none',
					padding = '0px',
				},
				children = {
					HtmlWidgets.Div{
						classes = {'content1'},
						css = {border = 'none'},
						children = self.props.children
					},
					HtmlWidgets.Div{
						classes = {'content2'},
						css = {border = 'none'},
					}
				}
			}
		}
	}
end

return CharacterStatsDetailsPopupContainer
