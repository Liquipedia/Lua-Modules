---
-- @Liquipedia
-- page=Module:Widget/Match/Page/MapVeto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Image = Lua.import('Module:Image')

local Map = Lua.import('Module:Map')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Link = Lua.import('Module:Widget/Basic/Link')

---@alias VetoRound {map: string, type: 'pick'|'ban'|'decider', round: integer, by: standardOpponent}

---@class MatchPageMapVetoParameters
---@field vetoRounds VetoRound[]

---@class MatchPageMapVeto: Widget
---@operator call(MatchPageMapVetoParameters): MatchPageMapVeto
---@field props MatchPageMapVetoParameters
local MatchPageMapVeto = Class.new(Widget)

---@return Widget
function MatchPageMapVeto:render()
	---@param vetoRound VetoRound
	---@return (string|Widget)[]
	local formatTitle = function(vetoRound)
		local teamDisplay = function()
			return mw.ext.TeamTemplate.teamicon(vetoRound.by.template)
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
			byText,
			HtmlWidgets.Span{
				classes = {'match-bm-map-veto-card-map-action'},
				children = actionType
			}
		)
	end

	---@param vetoRound VetoRound
	---@return Widget?
	local function createVetoCard(vetoRound)
		local mapData = Map.getMapByPageName(vetoRound.map)
		if not mapData then
			return
		end

		return HtmlWidgets.Div{
			classes = {'match-bm-map-veto-card', 'match-bm-map-veto-card--' .. vetoRound.type},
			children = {
				HtmlWidgets.Div{
					classes = {'match-bm-map-veto-card-image'},
					children = Image.display(mapData.image, nil, {size = 240, link = mapData.pageName}),
				},
				HtmlWidgets.Div{
					classes = {'match-bm-map-veto-card-title'},
					children = {
						Link{
							link = mapData.pageName,
							children = {
								HtmlWidgets.Div{
									classes = {'match-bm-map-veto-card-map-name'},
									children = mapData.displayName
								},
							}
						},
						HtmlWidgets.Div{
							classes = {'match-bm-map-veto-card-map-info'},
							children = formatTitle(vetoRound)
						},
					}
				}
			}
		}
	end

	return HtmlWidgets.Div{
		classes = {'match-bm-map-veto-cards'},
		children = WidgetUtil.collect(Array.map(self.props.vetoRounds, createVetoCard))
	}
end

return MatchPageMapVeto
