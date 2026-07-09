---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/MapVetoStart
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local I18n = Lua.import('Module:I18n')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local ARROW_LEFT = IconFa{iconName = 'startleft', size = '110%'}
local ARROW_RIGHT = IconFa{iconName = 'startright', size = '110%'}
local START_MAP_VETO = Html.B{children = I18n.translate('matchsummary-mapveto-start')}

---@param props {firstVeto: integer?, vetoFormat: string?}
---@return VNode?
local function MatchSummaryMapVetoStart(props)
	if not props.firstVeto then
		return
	end

	local format = props.vetoFormat and {'Veto Format: ', props.vetoFormat} or ''
	local children = {}
	if props.firstVeto == 1 then
		children = {
			START_MAP_VETO,
			ARROW_LEFT,
			format,
		}
	elseif props.firstVeto == 2 then
		children = {
			format,
			ARROW_RIGHT,
			START_MAP_VETO,
		}
	end

	return Html.Div{
		classes = {'brkts-popup-veto-row'},
		children = Array.map(children, function(child)
			return Html.Div{children = child}
		end)
	}
end

return Component.component(MatchSummaryMapVetoStart)
