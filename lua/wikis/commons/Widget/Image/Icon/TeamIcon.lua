---
-- @Liquipedia
-- page=Module:Widget/Image/Icon/TeamIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Span = HtmlWidgets.Span
local WidgetIcon = Lua.import('Module:Widget/Image/Icon')
local WidgetIconImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetIconFontawesome = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class TeamIconWidgetParameters
---@field imageLight string?
---@field imageDark string?
---@field page string?
---@field size string?
---@field noLink boolean?
---@field legacy boolean?

---@class TeamIconWidgetProps
---@field imageLight string?
---@field imageDark string?
---@field page string?
---@field size string
---@field noLink boolean?
---@field legacy boolean?

---@class TeamIconWidget: IconWidget
---@operator call(TeamIconWidgetParameters): TeamIconWidget
---@field props TeamIconWidgetProps
local TeamIcon = Class.new(WidgetIcon)
TeamIcon.defaultProps = {
	size = '100x50px',
}

---This is the TBD Team icon in Team Template. This will be replaced by the Icon for the TBD Team.
---This is a medium term solution until we have refactored and standardized more of the Team Template.
---Hopefully in the future we can remove this.
local TBD_FILLER_IMAGE = 'Filler 600px.png'

---@private
---@return Widget
function TeamIcon:_getDefaultIcon()
	return WidgetIconFontawesome{
		iconName = 'team_tbd',
	}
end

---@private
---@param image string
---@param size string
---@param link string
---@return Widget
function TeamIcon:_getIcon(image, size, link)
	return WidgetIconImage{
		imageLight = image,
		size = size,
		alignment = 'middle',
		link = link,
	}
end

---@private
---@param icon Widget
---@param onlyForTheme 'lightmode'|'darkmode'|nil
---@param isLegacy boolean
---@return Widget
function TeamIcon:_buildSpan(icon, onlyForTheme, isLegacy)
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
---@return string
function TeamIcon:_getPageLink()
	if self.props.noLink then
		return ''
	end
	return self.props.page or ''
end

---@return Widget|Widget[]
function TeamIcon:render()
	local size = self.props.size
	local isLegacy = self.props.legacy or false
	local imageLight = self.props.imageLight

	if imageLight == TBD_FILLER_IMAGE or not imageLight then
		return self:_buildSpan(self:_getDefaultIcon(), nil, false)
	end

	local link = self:_getPageLink()
	local imageDark = self.props.imageDark or imageLight
	local allmode = imageLight == imageDark
	if allmode then
		return self:_buildSpan(self:_getIcon(imageLight, size, link), nil, isLegacy)
	end
	return {
		self:_buildSpan(self:_getIcon(imageLight, size, link), 'lightmode', isLegacy),
		self:_buildSpan(self:_getIcon(imageDark, size, link), 'darkmode', isLegacy),
	}
end

return TeamIcon
