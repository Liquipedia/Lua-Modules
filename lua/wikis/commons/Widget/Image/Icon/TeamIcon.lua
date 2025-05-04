---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Image/Icon/TeamIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Image = require('Module:Image')
local Lua = require('Module:Lua')

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

---@param props { theme: 'lightmode'|'darkmode'|'allmode', legacy: boolean? }
---@return string[]
function TeamIcon._getSpanClasses(props)
	return Array.extend(
		'team-template-image-' .. props.legacy and 'legacy' or 'icon',
		props.theme ~= 'allmode' and ('team-template-' .. props.theme) or nil
	)
end

---@return string?
function TeamIcon:_getPageLink()
	return self.props.noLink and '' or self.props.page
end

---@return Widget|Widget[]
function TeamIcon:render()
	local imageLight = self.props.imageLight
	local imageDark = self.props.imageDark or self.props.imageLight
	local size = self.props.size
	local allmode = imageLight == imageDark

	local buildSpan = function(image, theme)
		return Span{
			classes = TeamIcon._getSpanClasses{theme = theme, legacy = self.props.legacy},
			children = {
				Image.display(image, nil, {
					size = size,
					alignment = 'middle',
					link = self:_getPageLink()
				})
			}
		}
	end

	if allmode then
		return buildSpan(imageLight, 'allmode')
	end
	return {
		buildSpan(imageLight, 'lightmode'),
		buildSpan(imageDark, 'darkmode')
	}
end

return TeamIcon
