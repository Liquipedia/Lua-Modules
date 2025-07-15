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
---@field imageLight string
---@field imageDark string?
---@field page string?
---@field size string?
---@field noLink boolean?
---@field legacy boolean?

---@class TeamIconWidgetProps
---@field imageLight string
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
---@return Widget
function TeamIcon:_getIcon(image, size)
	return WidgetIconImage{
		imageLight = image,
		size = size,
		alignment = 'middle',
		link = self:_getPageLink()
	}
end

---@private
---@param icon Widget
---@param onlyForTheme 'lightmode'|'darkmode'|nil
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
---@return string?
function TeamIcon:_getPageLink()
	return self.props.noLink and '' or self.props.page
end

---@return Widget|Widget[]
function TeamIcon:render()
	local size = self.props.size
	local isLegacy = self.props.legacy
	local imageLight = self.props.imageLight

	if imageLight == TBD_FILLER_IMAGE then
		return self:_buildSpan(self:_getDefaultIcon(), nil, false)
	end

	local imageDark = self.props.imageDark or imageLight
	local allmode = imageLight == imageDark
	if allmode then
		return self:_buildSpan(self:_getIcon(imageLight, size), nil, isLegacy)
	end
	return {
		self:_buildSpan(self:_getIcon(imageLight, size), 'lightmode', isLegacy),
		self:_buildSpan(self:_getIcon(imageDark, size), 'darkmode', isLegacy),
	}
end

return TeamIcon
