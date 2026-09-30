---
-- @Liquipedia
-- page=Module:Widget/WarningBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Html = Lua.import('Module:Widget/Html')

---@param props {text: string|number?}
---@return VNode?
local function WarningBox(props)
	local text = props.text
	if Logic.isEmpty(text) then
		return
	end
	---@cast text -nil

	local tbl = Html.Table{
		children = Html.Tr{
			children = {
				Html.Td{
					classes = {'ambox-image'},
					children = IconImage{imageLight = 'Emblem-important.svg', size = '40px', link = ''}
				},
				Html.Td{
					classes = {'ambox-text'},
					children = text
				},
			}
		}
	}

	return Html.Div{
		classes = {
			'show-when-logged-in',
			'navigation-not-searchable',
			'ambox-wrapper',
			'ambox',
			'wiki-bordercolor-dark',
			'wiki-backgroundcolor-light',
			'ambox-red'
		},
		children = tbl
	}
end

return Component.component(WarningBox)
