---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/MapVeto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Image = require('Module:Image')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

---@class MatchPageMapVetoParameters
---@field vetoRounds {name: string, link: string, type: 'pick'|'ban'|'decider', round: integer, by: standardOpponent}[]

---@class MatchPageMapVeto: Widget
---@operator call(MatchPageMapVetoParameters): MatchPageMapVeto
---@field props MatchPageMapVetoParameters
local MatchPageMapVeto = Class.new(Widget)

---@return Widget
function MatchPageMapVeto:render()
	local formatTitle = function(vetoRound)
		local teamDisplay = function()
			return OpponentDisplay.InlineOpponent({opponent = vetoRound.by, teamStyle = 'standard'})
		end
		local actionType
		local byText

		if vetoRound.type == 'pick' then
			actionType = 'Pick'
			byText = teamDisplay()
		elseif vetoRound.type == 'ban' then
			actionType = 'Ban'
			byText = teamDisplay()
		elseif vetoRound.type == 'protect' then
			actionType = 'Protect'
			byText = teamDisplay()
		elseif vetoRound.type == 'decider' then
			actionType = 'Decider'
		elseif vetoRound.type == 'defaultban' then
			actionType = 'Default Ban'
		end

		return WidgetUtil.collect(
			HtmlWidgets.Span{
				classes = {'match-bm-map-veto-card-map-action'},
				children = actionType
			},
			byText
		)
	end

	return HtmlWidgets.Div{
		classes = {'match-bm-map-veto-cards'},
		children = Array.map(self.props.vetoRounds, function(vetoRound)
			return HtmlWidgets.Div{
				classes = {'match-bm-map-veto-card', 'match-bm-map-veto-card--' .. vetoRound.type},
				children = {
					HtmlWidgets.Div{
						classes = {'match-bm-map-veto-card-image'},
						children = Image.display(vetoRound.name .. ' Map.png', nil, {size = 240, link = ''}),
					},
					HtmlWidgets.Div{
						classes = {'match-bm-map-veto-card-title'},
						children = {
							HtmlWidgets.Div{
								classes = {'match-bm-map-veto-card-map-name'},
								children = vetoRound.name
							},
							HtmlWidgets.Div{
								classes = {'match-bm-map-veto-card-map-info'},
								children = formatTitle(vetoRound)
							},
						}
					}
				}
			}
		end)
	}
end

return MatchPageMapVeto
