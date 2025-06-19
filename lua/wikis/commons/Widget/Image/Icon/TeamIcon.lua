---
-- @Liquipedia
-- page=Module:Widget/Image/Icon/TeamIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Image = Lua.import('Module:Image')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Span = HtmlWidgets.Span
local WidgetIcon = Lua.import('Module:Widget/Image/Icon')

local ICON_SIZE = '100x50px'

---@class TeamIconWidgetParameters
---@field imageLight string
---@field imageDark string?
---@field page string?
---@field size string?
---@field noLink boolean?
---@field legacy boolean?

---@class TeamIconWidget: IconWidget
---@operator call(TeamIconWidgetParameters): TeamIconWidget
---@field props TeamIconWidgetParameters
local TeamIcon = Class.new(WidgetIcon)
TeamIcon.defaultProps = {
	size = ICON_SIZE
}

---@private
---@param image string
---@param theme 'lightmode'|'darkmode'|'allmode'
---@return Widget
function TeamIcon:_buildSpan(image, theme)
	local size = self.props.size
	return Span{
		classes = Array.extend(
			'team-template-image-' .. (self.props.legacy and 'legacy' or 'icon'),
			theme ~= 'allmode' and ('team-template-' .. theme) or nil
		),
		children = {
			Image.display(image, nil, {
				size = size,
				alignment = 'middle',
				link = self:_getPageLink()
			})
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
	local imageLight = self.props.imageLight
	local imageDark = self.props.imageDark or self.props.imageLight
	local allmode = imageLight == imageDark

	if allmode then
		return self:_buildSpan(imageLight, 'allmode')
	end
	return {
		self:_buildSpan(imageLight, 'lightmode'),
		self:_buildSpan(imageDark, 'darkmode')
	}
end

return TeamIcon
