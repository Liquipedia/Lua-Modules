---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Opponent/Inline/Bracket
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

---@class TeamBracket: Widget
---@operator call(TeamInlineParameters): TeamBracket
---@field props TeamInlineParameters
local TeamBracket = Class.new(Widget)

---@return Widget
function TeamBracket:render()
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
				children = teamTemplate.bracketname,
				link = teamTemplate.page
			}}
		}
	}
	return Span{
		attributes = { ['data-highlighting-class'] = self.props.teamTemplate.name },
		classes = { 'team-template-team' .. (flip and '2' or '') .. '-Bracket' },
		children = flip and Array.reverse(children) or children
	}
end

return TeamBracket
