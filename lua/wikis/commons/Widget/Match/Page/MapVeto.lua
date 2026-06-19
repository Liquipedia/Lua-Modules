---
-- @Liquipedia
-- page=Module:Widget/Match/Page/MapVeto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Image = Lua.import('Module:Image')

local Map = Lua.import('Module:Map')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Link = Lua.import('Module:Widget/Basic/Link')
local VetoLabel = Lua.import('Module:Widget/Match/Summary/VetoLabel')

---@alias VetoRound {map: string, type: 'pick'|'ban'|'decider', round: integer, by: standardOpponent}

---@class MatchPageMapVetoParameters
---@field vetoRounds VetoRound[]

---@param vetoRound VetoRound
---@return Renderable[]
local formatTitle = function(vetoRound)
	local teamDisplay = function()
		return OpponentDisplay.InlineOpponent{
			opponent = vetoRound.by,
			teamStyle = 'icon',
		}
	end
	local byText

	if vetoRound.type == 'pick' then
		byText = teamDisplay()
	elseif vetoRound.type == 'ban' then
		byText = teamDisplay()
	elseif vetoRound.type == 'protect' then
		byText = teamDisplay()
	end

	return WidgetUtil.collect(
		byText,
		VetoLabel{vetoType = vetoRound.type}
	)
end

---@param vetoRound VetoRound
---@return HtmlNode?
local function createVetoCard(vetoRound)
	local mapData = Map.getMapByPageName(vetoRound.map)
	if not mapData then
		return
	end

	return Html.Div{
		classes = {'match-bm-map-veto-card', 'match-bm-map-veto-card--' .. vetoRound.type},
		children = {
			Html.Div{
				classes = {'match-bm-map-veto-card-image'},
				children = Image.display(mapData.image, nil, {size = 240, link = mapData.pageName}),
			},
			Html.Div{
				classes = {'match-bm-map-veto-card-title'},
				children = {
					Link{
						link = mapData.pageName,
						children = {
							Html.Div{
								classes = {'match-bm-map-veto-card-map-name'},
								children = mapData.displayName
							},
						}
					},
					Html.Div{
						classes = {'match-bm-map-veto-card-map-info'},
						children = formatTitle(vetoRound)
					},
				}
			}
		}
	}
end

local function MatchPageMapVeto(props)
	return Html.Div{
		classes = {'match-bm-map-veto-cards'},
		children = WidgetUtil.collect(Array.map(props.vetoRounds, createVetoCard))
	}
end

return Component.component(MatchPageMapVeto)
