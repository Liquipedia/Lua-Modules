---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Image/Icon/TeamIcon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

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
---@field nolink boolean?
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
	return {
		'team-template-image-' .. props.legacy and 'legacy' or 'icon',
		'team-template-' .. props.theme
	}
end

---@return string?
function TeamIcon:_getPageLink()
	return self.props.nolink and '' or self.props.page
end

---@return Widget|Widget[]
function TeamIcon:render()
	local imageLight = self.props.imageLight
	local imageDark = self.props.imageDark or self.props.imageLight
	local allmode = imageLight == imageDark
	if allmode then
		return HtmlWidgets.Span{
			classes = TeamIcon._getSpanClasses{theme = 'allmode', legacy = self.props.legacy},
			children = {
				Image.display(imageLight, nil, {
					size = ICON_SIZE,
					alignment = 'middle',
					link = self:_getPageLink()
				})
			}
		}
	end
	return {
		Span{
			classes = TeamIcon._getSpanClasses{theme = 'lightmode'},
			children = {
				Image.display(imageLight, nil, {
					size = ICON_SIZE,
					alignment = 'middle',
					link = self:_getPageLink()
				})
			}
		},
		Span{
			classes = TeamIcon._getSpanClasses{theme = 'darkmode'},
			children = {
				Image.display(imageDark, nil, {
					size = ICON_SIZE,
					alignment = 'middle',
					link = self:_getPageLink()
				})
			}
		}
	}
end

return TeamIcon
