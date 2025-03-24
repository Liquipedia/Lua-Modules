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
local Table = require('Module:Table') ---@module 'commons.Table'
local TeamTemplate = require('Module:TeamTemplate') ---@module 'commons.TeamTemplate'

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Span = HtmlWidgets.Span
local TeamIcon = Lua.import('Module:Widget/Image/Icon/TeamIcon')
local TeamName = Lua.import('Module:Widget/TeamDisplay/Component/Name')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class InlineType
---@field displayType string
---@field displayNames table<string, string[]>

---@type table<string, InlineType>
local TeamInlineTypes = {
	['bracket'] = {
		displayType = 'bracket',
		displayNames = {['bracketname'] = {}}
	},
	['icon'] = {
		displayType = 'icon',
		displayNames = {}
	},
	['short'] = {
		displayType = 'short',
		displayNames = {['shortname'] = {}}
	},
	['standard'] = {
		displayType = 'standard',
		displayNames = {['name'] = {}}
	}
}

---@class TeamInlineParameters
---@field name string?
---@field date number|string?
---@field teamTemplate teamTemplateData?
---@field flip boolean?
---@field displayType 'bracket'|'icon'|'short'|'standard'|'hybrid'

---@class TeamInlineWidget: Widget
---@operator call(TeamInlineParameters): TeamInlineWidget
---@field name string?
---@field props TeamInlineParameters
---@field teamTemplate teamTemplateData
---@field flip boolean
---@field displayType InlineType
local TeamInlineWidget = Class.new(Widget,
	---@param self self
	---@param input TeamInlineParameters
	function (self, input)
		assert(TeamInlineTypes[input.displayType], 'Invalid display type')
		self.teamTemplate = input.teamTemplate or TeamTemplate.getRawOrNil(input.name, input.date)
		self.name = (self.teamTemplate or {}).name or input.name
		self.flip = Logic.readBool(input.flip)
		self.displayType = TeamInlineTypes[input.displayType]
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
		self:getNameComponent()
	), ' ')
	return Span{
		attributes = { ['data-highlighting-class'] = self.teamTemplate.name },
		classes = { 'team-template-team' .. (flip and '2' or '') .. '-' .. self:getType() },
		children = flip and Array.reverse(children) or children
	}
end

---@return Widget
function TeamInlineWidget:getNameComponent()
	return HtmlWidgets.Fragment{
		children = Array.map(Table.entries(self.displayType.displayNames), function (element)
			return TeamName{
				additionalClasses = element[2],
				displayName = self.teamTemplate[element[1]],
				page = self.teamTemplate.page
			}
		end)
	}
end

return TeamInlineWidget
