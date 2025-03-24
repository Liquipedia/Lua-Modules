---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/TeamDisplay/Inline
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local TeamTemplate = require('Module:TeamTemplate') ---@module 'commons.TeamTemplate'

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local Span = HtmlWidgets.Span
local TeamIcon = Lua.import('Module:Widget/Image/Icon/TeamIcon')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class TeamInlineParameters
---@field name string?
---@field date number|string?
---@field teamTemplate teamTemplateData?
---@field flip boolean?

---@class TeamInlineWidget: Widget
---@operator call(TeamInlineParameters): TeamInlineWidget
---@field name string?
---@field props TeamInlineParameters
---@field teamTemplate teamTemplateData
---@field flip boolean
local TeamInlineWidget = Class.new(Widget,
	---@param self self
	---@param input TeamInlineParameters
	function (self, input)
		self.teamTemplate = input.teamTemplate or TeamTemplate.getRawOrNil(input.name, input.date)
		self.name = (self.teamTemplate or {}).name or input.name
		self.flip = Logic.readBool(input.flip)
	end
)

---@return Widget
function TeamInlineWidget:render()
	local teamTemplate = self.teamTemplate
	if not teamTemplate then
		mw.ext.TeamLiquidIntegration.add_category('Pages with missing team templates')
		return HtmlWidgets.Small{
			classes = { 'error' },
			children = { TeamTemplate.noTeamMessage(self.name) }
		}
	end
	local flip = self.flip
	local children = Array.interleave(WidgetUtil.collect(
		TeamIcon{
			imageLight = self.teamTemplate.image,
			imageDark = self.teamTemplate.imagedark,
			page = self.teamTemplate.page,
			nolink = self.teamTemplate.nolink
		},
		String.isNotEmpty(self:getDisplayName()) and Span{
			classes = { 'team-template-text' },
			children = {
				teamTemplate.nolink and self:getDisplayName() or Link{
					children = self:getDisplayName(),
					link = teamTemplate.page
				}
			}
		} or nil
	), ' ')
	return Span{
		attributes = { ['data-highlighting-class'] = self.teamTemplate.name },
		classes = { 'team-template-team' .. (flip and '2' or '') .. '-' .. self:getType() },
		children = flip and Array.reverse(children) or children
	}
end

---@return string
function TeamInlineWidget:getType()
	error('TeamInlineWidget:getType() cannot be called directly and must be overridden.')
end

---@return string
function TeamInlineWidget:getDisplayName()
	error('TeamInlineWidget:getDisplayName() cannot be called directly and must be overridden.')
end

return TeamInlineWidget
