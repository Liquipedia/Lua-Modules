---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Widget/Image/Icon/Creds
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')

---@class ValorantCredsIconWidget: IconWidget
---@operator call(): ValorantCredsIconWidget
local ValorantCredsIconWidget = Class.new(Widget)

---@return Widget
function ValorantCredsIconWidget:render()
	return HtmlWidgets.Span{
		css = { ['white-space'] = 'nowrap'},
		children = {
			IconImageWidget{
				imageLight = 'Black_Creds_VALORANT.png',
				imageDark = 'White_Creds_VALORANT.png',
				link = 'Creds',
				size = '10px'
			}
		}
	}
end

return ValorantCredsIconWidget
