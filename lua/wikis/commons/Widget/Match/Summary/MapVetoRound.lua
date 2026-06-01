---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/MapVetoRound
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local VetoLabel = Lua.import('Module:Widget/Match/Summary/VetoLabel')

---@alias VetoMap {name: string, page: string?}

---@param props {vetoType: VetoTypes, map1: VetoMap?, map2: VetoMap?}
---@return Widget?
local function MatchSummaryMapVetoRound(props)
	local vetoType = props.vetoType
	if not vetoType then
		return
	end

	---@param map {name: string, page: string?}
	---@return Renderable
	local function displayMap(map)
		if not map.page then
			return map.name
		end
		return Link{
			children = map.name,
			link = map.page,
		}
	end

	local vetoLabel = VetoLabel{vetoType = vetoType}

	local children
	if vetoType == 'decider' then
		children = {
			Html.Div{
				children = vetoLabel
			},
			Html.Div{
				children = displayMap(props.map1)
			},
			Html.Div{
				children = vetoLabel
			},
		}
	else
		children = {
			Html.Div{
				children = displayMap(props.map1)
			},
			Html.Div{
				children = vetoLabel
			},
			Html.Div{
				children = displayMap(props.map2)
			},
		}
	end

	return Html.Div{classes = {'brkts-popup-veto-row'}, children = children}
end

return Component.component(MatchSummaryMapVetoRound)
