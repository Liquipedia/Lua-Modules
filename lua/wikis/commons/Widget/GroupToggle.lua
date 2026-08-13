---
-- @Liquipedia
-- page=Module:Widget/GroupToggle
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = require('Module:Logic')
local Table = require('Module:Table')

local Component = Lua.import('Module:Widget/Component')

local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local CollapsibleToggle = Lua.import('Module:Widget/GeneralCollapsible/Toggle')
local Html = Lua.import('Module:Widget/Html')
local B = Html.B
local Div = Html.Div
local Span = Html.Span

---@alias GroupTableProps {
---bracket: string,
---width: string?,
---done: boolean|string?,
---collapsed: boolean|string?,
---title: string?,
---group: string,
---win1: string?,
---}

---@param props GroupTableProps
---@return VNode?
local function GroupToggle(props)
	local title = (props.title or 'Group') .. ' ' .. props.group .. ': '
	local winners = {}

	if not props.win1 then
		table.insert(winners, 'TBD')
	end

	for _, winner in Table.iter.pairsByPrefix(props, 'win') do
		table.insert(winners, tostring(B{children = winner}))
	end

	return Collapsible{
		css = {
			['width'] = props.width,
			['max-width'] = '100%',
			['margin-bottom'] = '10px',
		},
		shouldCollapse = Logic.readBool(props.collapsed) or Logic.readBool(props.done),
		titleWidget = Div{
			classes = {'general-collapsible-default-title'},
			children = {
				B{
					classes = {'wiki-backgroundcolor-light'},
					css = {
						['padding'] = '0 1em',
					},
					children = title,
				},
				Span{
					css = {
						['padding-left'] = '0.25em'
					},
					children = {
						mw.text.listToText(winners),
						#winners == 1 and ' advances.' or ' advance.',
					}
				},
				CollapsibleToggle{css = {float = 'right'}},
			}
		},
		collapseAreaCss = {
			['padding-top'] = '5px'
		},
		children = props.bracket,
	}

end

return Component.component(GroupToggle, {width = '700px'})
