---
-- @Liquipedia
-- page=Module:Widget/Match/VodButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local VodLink = Lua.import('Module:VodLink')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Button = Lua.import('Module:Widget/Basic/Button')
local ImageIcon = Lua.import('Module:Widget/Image/Icon/Image')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@param props {vodLink: string, variant: string?, showText: boolean?, gameNumber: integer, grow: boolean?}
---@return VNode?
local function VodButton(props)
	local vodLink = props.vodLink

	if not vodLink then
		return
	end

	local useDropdownVariant = props.variant == 'dropdown'
	local showText = props.showText
	local gameNumber = props.gameNumber
	local useGrow = Logic.readBool(props.grow)

	return Button{
		linktype = 'external',
		title = VodLink.getTitle(gameNumber),
		variant = 'secondary',
		link = vodLink,
		size = 'sm',
		grow = useGrow,
		children = useDropdownVariant and {
			Icon{iconName = 'vod_play', size = 'sm'},
			Html.Span{
				children = showText and ('Game ' .. gameNumber) or gameNumber,
			}
		} or {
			ImageIcon{imageLight = VodLink.getIcon(gameNumber)},
			Html.Span{
				classes = {'match-button-cta-text'},
				children = 'Watch VOD',
			},
		},
	}
end

return Component.component(VodButton)
