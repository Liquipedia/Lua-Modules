---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/MapVeto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local MapVetoStart = Lua.import('Module:Widget/Match/Summary/MapVetoStart')
local MapVetoRound = Lua.import('Module:Widget/Match/Summary/MapVetoRound')

---@class MapVetoProps
---@field vetoFormat string
---@field firstVeto integer?
---@field vetoRounds {type: VetoTypes, map1: VetoMap?, map2: VetoMap?}[]

---@param props MapVetoProps
---@return VNode?
local function MatchSummaryMapVeto(props)
	if Logic.isEmpty(props.vetoRounds) then
		return
	end

	return GeneralCollapsible{
		classes = {'brkts-popup-veto-wrapper'},
		shouldCollapse = true,
		collapseAreaClasses = {'brkts-popup-veto'},
		titleClasses = {'brkts-popup-veto-header'};
		title = 'Map Veto',
		children = WidgetUtil.collect(
			MapVetoStart{firstVeto = props.firstVeto, vetoFormat = props.vetoFormat},
			Array.map(props.vetoRounds, function(veto)
				return MapVetoRound{vetoType = veto.type, map1 = veto.map1, map2 = veto.map2}
			end)
		)
	}
end

return Component.component(MatchSummaryMapVeto)
