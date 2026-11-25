---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/MatchHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local NON_BREAKING_SPACE = '&nbsp;'

---@class BracketMatchHeaderProps
---@field height number
---@field header string
---@field isThirdPlaceMatch boolean?
---@field hasBracketReset boolean?
---@field skipRound integer?
---@field headerMargin number?

---Display component for a header to a match.
---@param props BracketMatchHeaderProps
---@return VNode
local function BracketMatchHeader(props)
	local options = DisplayHelper.expandHeader(props.header)

	return Html.Div{
		classes = Array.appendWith(
			{'brkts-header', 'brkts-header-div'},
			options[1] == NON_BREAKING_SPACE and 'brkts-header-nodisplay' or nil,
			props.hasBracketReset and 'brkts-br-wrapper' or nil,
			props.isThirdPlaceMatch and 'brkts-third-place-header' or nil
		),
		css = {
			height = props.height .. 'px',
			['line-height'] = (props.height - 11) .. 'px',
			['--skip-round'] = props.skipRound,
			['margin-top'] = props.headerMargin and (20 + props.headerMargin .. 'px') or nil,
			['margin-bottom'] = props.headerMargin and (props.headerMargin .. 'px') or nil,
		},
		children = Array.extend(
			options[1],
			-- Don't emit brkts-header-option if there is only one option. This is
			-- because the JavaScript module for changing headers supports only text,
			-- and will eat up tags like <abbr>.
			#options > 1 and Array.map(options, function (option)
				return Html.Div{
					classes = {'brkts-header-option'},
					children = option,
				}
			end) or nil
		)
	}
end

return Component.component(BracketMatchHeader)
