---
-- @Liquipedia
-- page=Module:Widget/Match/VodsDropdownButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local VodLink = Lua.import('Module:VodLink')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Button = Lua.import('Module:Widget/Basic/Button')
local ImageIcon = Lua.import('Module:Widget/Image/Icon/Image')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Span = Html.Span

---@class VodsDropdownButtonProps
---@field count integer?
---@field css? HtmlStyleProps
---@field attributes? table<string, string|number?>

---@param props VodsDropdownButtonProps
---@return VNode?
local function VodsDropdownButton(props)
	local vodCount = props.count
	if not vodCount then
		return
	end

	local showButton = Button{
		classes = {'general-collapsible-expand-button'},
		children = Span{
			children = {
				ImageIcon{imageLight = VodLink.getIcon()},
				' ',
				'(' .. vodCount .. ')',
				' ',
				Icon{iconName = 'expand'},
			},
		},
		size = 'sm',
		variant = 'secondary',
	}
	local hideButton = Button{
		classes = {'general-collapsible-collapse-button', 'button--active'},
		children = Span{
			children = {
				ImageIcon{imageLight = VodLink.getIcon()},
				' ',
				'(' .. vodCount .. ')',
				' ',
				Icon{iconName = 'collapse'},
			},
		},
		size = 'sm',
		variant = 'secondary',
	}

	return Span{
		classes = {'general-collapsible-default-toggle'},
		css = props.css,
		attributes = props.attributes,
		children = {
			showButton,
			hideButton,
		}
	}
end

return Component.component(VodsDropdownButton)
