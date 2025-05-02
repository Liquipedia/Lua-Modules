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

---@class MatchPageMapVetoParameters
---@field vetoRounds {name: string, link: string, type: 'pick'|'ban'|'decider', round: integer, by: standardOpponent}[]

---@class MatchPageMapVeto: Widget
---@operator call(MatchPageMapVetoParameters): MatchPageMapVeto
---@field props MatchPageMapVetoParameters
local MatchPageMapVeto = Class.new(Widget)

---@return Widget
function MatchPageMapVeto:render()
	local formatTitle = function(vetoRound)
		local actionType
		local byText = ''

		if vetoRound.type == 'pick' then
			actionType = 'Pick'
			byText = ' ' .. vetoRound.by.name
		elseif vetoRound.type == 'ban' then
			actionType = 'Ban'
			byText = ' ' .. vetoRound.by.name
		elseif vetoRound.type == 'decider' then
			actionType = 'Decider'
		end

		return HtmlWidgets.Div{
			classes = {'match-bm-map-veto-card-map-info'},
			children = {
				HtmlWidgets.Span{
					classes = {'match-bm-map-veto-card-map-action'},
					children = actionType
				},
				byText
			}
		}
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
							formatTitle(vetoRound)
						}
					}
				}
			}
		end)
	}
end

return MatchPageMapVeto
