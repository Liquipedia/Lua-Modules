---
-- @Liquipedia
-- page=Module:Widget/Match/Bracket/MatchHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local NON_BREAKING_SPACE = '&nbsp;'

---Display component for a header to a match.
---@param props {additionalClasses: string[]?, css: HtmlStyleProps?, height: number, header: string}
---@return VNode
local function BracketMatchHeader(props)
	local options = DisplayHelper.expandHeader(props.header)

	return Html.Div{
		classes = Array.extend(
			'brkts-header',
			'brkts-header-div',
			--do not display the header if it is "&nbsp;"
			options[1] == NON_BREAKING_SPACE and 'brkts-header-nodisplay' or nil,
			props.additionalClasses
		),
		css = Table.mergeInto({
			height = props.height .. 'px',
			['line-height'] = props.height - 11 .. 'px',
		}, props.css),
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
