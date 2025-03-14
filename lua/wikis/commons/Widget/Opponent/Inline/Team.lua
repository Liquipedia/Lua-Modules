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

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Span = HtmlWidgets.Span

---@class TeamInlineParameters
---@field name string?
---@field date number|string?
---@field teamTemplate teamTemplateData?
---@field flip boolean?

---@class TeamInline: Widget
---@operator call(TeamInlineParameters): TeamInline
---@field props TeamInlineParameters
local TeamInline = Class.new(Widget)

---@return Widget
function TeamInline:render()
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
				children = teamTemplate.name,
				link = teamTemplate.page
			}}
		}
	}
	return Span{
		attributes = { ['data-highlighting-class'] = self.props.teamTemplate.name },
		classes = { 'team-template-team' .. (flip and '2' or '') .. '-standard' },
		children = flip and Array.reverse(children) or children
	}
end

return TeamInline
