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

---@class TeamIconParameters
---@field teamTemplate teamTemplateData

---@class TeamIcon: IconWidget
---@operator call(TeamIconParameters): TeamIcon
---@field props TeamIconParameters
local TeamIconWidget = Class.new(WidgetIcon)

---@return Widget
function TeamIconWidget:render()
	local teamTemplate = self.props.teamTemplate
	return Span{
		attributes = { ['data-highlighting-class'] = self.props.teamTemplate.name },
		classes = { 'team-template-team-icon' },
		children = {
			Span{
				classes = { 'team-template-image-icon', 'team-template-lightmode' },
				children = {
					Image.display(teamTemplate.image, nil, {
						size = '100x50px',
						alignment = 'middle',
						link = teamTemplate.page
					})
				}
			},
			Span{
				classes = { 'team-template-image-icon', 'team-template-lightmode' },
				children = {
					Image.display(teamTemplate.imagedark, nil, {
						size = '100x50px',
						alignment = 'middle',
						link = teamTemplate.page
					})
				}
			}
		}
	}
end

return TeamIconWidget
