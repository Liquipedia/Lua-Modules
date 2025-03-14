---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Opponent/Inline
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Image = require('Module:Image')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local TeamTemplate = require('Module:TeamTemplate')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Span = HtmlWidgets.Span
local WidgetUtil = Lua.import('Module:Widget/Util')

local ICON_SIZE = '100x50px'

---@class TeamInlineParameters
---@field name string?
---@field date number|string?
---@field teamTemplate teamTemplateData?
---@field flip boolean?

---@class TeamInlineWidget: Widget
---@operator call(TeamInlineParameters): TeamInlineWidget
---@field props TeamInlineParameters
---@field teamTemplate teamTemplateData
---@field flip boolean
local TeamInlineWidget = Class.new(Widget,
	function (self, input)
		self.teamTemplate = input.teamTemplate or TeamTemplate.getRaw(input.name, input.date)
		self.flip = Logic.readBool(input.flip)
	end
)

---@return Widget
function TeamInlineWidget:render()
	local teamTemplate = self.teamTemplate
	local flip = self.flip
	local children = Array.interleave(WidgetUtil.collect(
		HtmlWidgets.Fragment{children = {
			Span{
				classes = { 'team-template-image-icon', 'team-template-lightmode' },
				children = {
					Image.display(teamTemplate.image, nil, {
						size = ICON_SIZE,
						alignment = 'middle',
						link = teamTemplate.page
					})
				}
			},
			Span{
				classes = { 'team-template-image-icon', 'team-template-lightmode' },
				children = {
					Image.display(teamTemplate.imagedark, nil, {
						size = ICON_SIZE,
						alignment = 'middle',
						link = teamTemplate.page
					})
				}
			}
		}},
		String.isNotEmpty(TeamInlineWidget:getDisplayName()) and Span{
			classes = 'team-template-text',
			children = {Link{
				children = TeamInlineWidget:getDisplayName(),
				link = teamTemplate.page
			}}
		} or nil
	), ' ')
	return Span{
		attributes = { ['data-highlighting-class'] = self.props.teamTemplate.name },
		classes = { 'team-template-team' .. (flip and '2' or '') .. '-' .. self:getType() },
		children = flip and Array.reverse(children) or children
	}
end

---@return string
function TeamInlineWidget:getType()
	error('Widget/Opponent/Inline is an abstract implementation and should not be instantiated directly')
end

---@return string
function TeamInlineWidget:getDisplayName()
	error('Widget/Opponent/Inline is an abstract implementation and should not be instantiated directly')
end

return TeamInlineWidget
