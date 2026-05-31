---
-- @Liquipedia
-- page=Module:Widget/Image/Icon/TeamIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Span = Html.Span
local WidgetIconImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetIconFontawesome = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class TeamIconWidgetProps
---@field imageLight string?
---@field imageDark string?
---@field name string?
---@field page string?
---@field size string
---@field noLink boolean?
---@field legacy boolean?

---This is the TBD Team icon in Team Template. This will be replaced by the Icon for the TBD Team.
---This is a medium term solution until we have refactored and standardized more of the Team Template.
---Hopefully in the future we can remove this.
local TBD_FILLER_IMAGE = 'Filler 600px.png'

local TeamIcon = {}
TeamIcon.defaultProps = {
	size = '100x50px',
}

local Helpers = {}

---@param props TeamIconWidgetProps
---@return VNode|VNode[]
function TeamIcon.render(props)
	local size = props.size
	local isLegacy = props.legacy or false
	local imageLight = props.imageLight
	local name = props.name

	if imageLight == TBD_FILLER_IMAGE or not imageLight then
		return Helpers._buildSpan(Helpers._getDefaultIcon(), nil, false)
	end

	local link = Helpers._getPageLink(props)
	local imageDark = props.imageDark or imageLight
	local allmode = imageLight == imageDark
	if allmode then
		return Helpers._buildSpan(Helpers._getIcon(imageLight, size, link, name), nil, isLegacy)
	end
	return {
		Helpers._buildSpan(Helpers._getIcon(imageLight, size, link, name), 'lightmode', isLegacy),
		Helpers._buildSpan(Helpers._getIcon(imageDark, size, link, name), 'darkmode', isLegacy),
	}
end

---@private
---@return Widget
function Helpers._getDefaultIcon()
	return WidgetIconFontawesome{
		iconName = 'team_tbd',
	}
end

---@private
---@param image string
---@param size string
---@param link string
---@param name string?
---@return Widget
function Helpers._getIcon(image, size, link, name)
	return WidgetIconImage{
		imageLight = image,
		size = size,
		verticalAlignment = 'middle',
		caption = name,
		link = link,
	}
end

---@private
---@param icon Widget
---@param onlyForTheme 'lightmode'|'darkmode'|nil
---@param isLegacy boolean
---@return Widget
function Helpers._buildSpan(icon, onlyForTheme, isLegacy)
	return Span{
		classes = Array.extend(
			'team-template-image-' .. (isLegacy and 'legacy' or 'icon'),
			onlyForTheme and ('team-template-' .. onlyForTheme) or nil
		),
		children = {
			icon,
		}
	}
end

---@private
---@param props TeamIconWidgetProps
---@return string
function Helpers._getPageLink(props)
	if props.noLink then
		return ''
	end
	return props.page or ''
end

return Component.component(TeamIcon.render, TeamIcon.defaultProps)
