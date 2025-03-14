---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Opponent/Inline/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Image = require('Module:Image')
local Lua = require('Module:Lua')
local TeamTemplate = require('Module:TeamTemplate')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Span = HtmlWidgets.Span
local WidgetIcon = Lua.import('Module:Widget/Image/Icon')

---@class TeamShort: Widget
---@operator call(TeamInlineParameters): TeamShort
---@field props TeamInlineParameters
local TeamShort = Class.new(WidgetIcon)

---@return Widget
function TeamShort:render()
	local teamTemplate = self.props.teamTemplate or TeamTemplate.getRaw(self.props.name, self.props.date)
	local flip = self.props.flip
	local children = {
		HtmlWidgets.Fragment{children = {
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
		}},
		' ',
		Span{
			classes = 'team-template-text',
			children = {Link{
				children = teamTemplate.shortname,
				link = teamTemplate.page
			}}
		}
	}
	return Span{
		attributes = { ['data-highlighting-class'] = self.props.teamTemplate.name },
		classes = { 'team-template-team' .. (flip and '2' or '') .. '-short' },
		children = flip and Array.reverse(children) or children
	}
end

return TeamShort
