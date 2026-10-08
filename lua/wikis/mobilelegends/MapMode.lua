---
-- @Liquipedia
-- page=Module:MapMode
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Data = Lua.import('Module:MapMode/Data', {loadData = true})

local MapMode = {}

---@param input string?
---@return string?
function MapMode.getKey(input)
	if Logic.isEmpty(input) then
		return
	end

	---@cast input string
	local lowered = string.lower(mw.text.trim(input))
	local key = Data.aliases[lowered] or lowered

	if Data.mode[key] then
		return key
	end
end

---@param input string?
---@return Renderable?
function MapMode.display(input)
	local key = MapMode.getKey(input)
	local data = key and Data.mode[key]
	if not data then
		return
	end

	local icon = Logic.isNotEmpty(data.file) and IconImage{
		imageLight = data.file,
		link = data.link,
		alt = data.display,
	} or nil

	return Html.B{
		children = WidgetUtil.collect(
			icon,
			icon and ' ' or nil,
			Link{link = data.link, children = data.display}
		),
	}
end

return MapMode
