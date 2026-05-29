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
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local IconFontawesome = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class TeamIconWidgetProps
---@field imageLight string?
---@field imageDark string?
---@field name string?
---@field page string?
---@field size string?
---@field noLink boolean?
---@field legacy boolean?

local defaultProps = {
	size = '100x50px',
}

---This is the TBD Team icon in Team Template. This will be replaced by the Icon for the TBD Team.
---This is a medium term solution until we have refactored and standardized more of the Team Template.
---Hopefully in the future we can remove this.
local TBD_FILLER_IMAGE = 'Filler 600px.png'
local TEAM_DEFAULT_ICON = IconFontawesome{iconName = 'team_tbd'}

---@param icon Renderable
---@param onlyForTheme 'lightmode'|'darkmode'|nil
---@param isLegacy boolean
---@return VNode
local function buildSpan(icon, onlyForTheme, isLegacy)
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

---@param page string?
---@param noLink boolean?
---@return string
local function getPageLink(page, noLink)
	if noLink then
		return ''
	end
	return page or ''
end

---@param props TeamIconWidgetProps
---@return VNode|VNode[]
local function TeamIcon(props)
	local isLegacy = props.legacy or false
	local imageLight = props.imageLight

	if imageLight == TBD_FILLER_IMAGE or not imageLight then
		return buildSpan(TEAM_DEFAULT_ICON, nil, false)
	end

	local link = getPageLink(props.page, props.noLink)

	---@param image string
	---@return Widget
	local function getIcon(image)
		return IconImage{
			imageLight = image,
			size = props.size,
			verticalAlignment = 'middle',
			caption = props.name,
			link = link,
		}
	end

	local imageDark = props.imageDark or imageLight
	local allmode = imageLight == imageDark
	if allmode then
		return buildSpan(getIcon(imageLight), nil, isLegacy)
	end
	return {
		buildSpan(getIcon(imageLight), 'lightmode', isLegacy),
		buildSpan(getIcon(imageDark), 'darkmode', isLegacy),
	}
end

return Component.component(TeamIcon, defaultProps)
