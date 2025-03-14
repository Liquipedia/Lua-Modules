---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Opponent/Inline/Icon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Image = require('Module:Image')
local Lua = require('Module:Lua')
local TeamTemplate = require('Module:TeamTemplate')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Span = HtmlWidgets.Span

---@class TeamIconParameters
---@field name string?
---@field date number|string?
---@field teamTemplate teamTemplateData?

---@class TeamIcon: IconWidget
---@operator call(TeamIconParameters): TeamIcon
---@field props TeamIconParameters
local TeamIconWidget = Class.new(Widget)

---@return Widget
function TeamIconWidget:render()
	local teamTemplate = self.props.teamTemplate or TeamTemplate.getRaw(self.props.name, self.props.date)
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
