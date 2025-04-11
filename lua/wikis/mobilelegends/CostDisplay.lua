---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:CostDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Data = Lua.import('Module:CostDisplay/Data', {loadData = true})
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')

local CostDisplay = {}

---@param costName string
---@param value string
---@return Widget
function CostDisplay.run(costName, value)
	if Logic.isEmpty(value) then return nil end
	local iconData = Data[costName]
	if not iconData then return nil end

	return HtmlWidgets.Span{
		css = {['white-space'] = 'nowrap'},
		children = {
			IconImageWidget{
				imageLight = iconData.icon,
				link = iconData.link,
				size = '15px'
			}, ' ', value
		}
	}
end

return Class.export(CostDisplay)
