---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/MapVeto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local MapVetoRound = Lua.import('Module:Widget/Match/Summary/MapVetoRound')
local WidgetUtil = Lua.import('Module:Widget/Util')

local ARROW_LEFT = IconFa{iconName = 'startleft', size = '110%'}
local ARROW_RIGHT = IconFa{iconName = 'startright', size = '110%'}

---@class MatchPageMapVeto: Widget
---@operator call(table): MatchPageMapVeto
---@field props table
local MatchPageMapVeto = Class.new(Widget)

---@return Widget?
function MatchPageMapVeto:render()
	if Logic.isEmpty(self.props.vetoRounds) then return end
	return Div{
		classes = {'collapsed', 'general-collapsible'},
		children = {
			Div{
				classes = {'match-bm-lol-game-veto-order-toggle', 'ppt-toggle-expand'},
				children = {
					Div{
						classes = {'general-collapsible-expand-button'},
						children = Div{children = {
							'Show Map Veto &nbsp;',
							IconFa{iconName = 'expand'}
						}}
					},
					Div{
						classes = {'general-collapsible-collapse-button'},
						children = Div{children = {
							'Hide Map Veto &nbsp;',
							IconFa{iconName = 'collapse'}
						}}
					}
				}
			},
			Div{
				classes = {'ppt-hide-on-collapse'},
				children = HtmlWidgets.Table{
					classes = {'match-bm-match-mapveto', 'brkts-popup-mapveto', 'wikitable-striped'},
					children = WidgetUtil.collect(
						self:_renderVetoStart(),
						Array.map(self.props.vetoRounds, function(veto)
							return MapVetoRound{vetoType = veto.type, map1 = veto.map1, map2 = veto.map2}
						end)
					)
				}
			}
		}
	}
end

---@private
---@return Widget
function MatchPageMapVeto:_renderVetoStart()
	local firstVeto = self.props.firstVeto
	local format = self.props.vetoFormat and ('Veto Format: ' .. self.props.vetoFormat) or ''
	local children = {}
	if firstVeto == 1 then
		children = {
			'<b>Start Map Veto</b>',
			ARROW_LEFT,
			format,
		}
	elseif firstVeto == 2 then
		children = {
			format,
			ARROW_RIGHT,
			'<b>Start Map Veto</b>',
		}
	end

	return HtmlWidgets.Tr{
		classes = {'brkts-popup-mapveto-vetostart'},
		children = Array.map(children, function(child, childIndex)
			return HtmlWidgets.Th{
				css = {width = childIndex == 2 and '34%' or '33%'},
				children = child
			}
		end)
	}
end

return MatchPageMapVeto
