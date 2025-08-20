---
-- @Liquipedia
-- page=Module:Widget/TeamDisplay/Block
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local TeamIcon = Lua.import('Module:Widget/Image/Icon/TeamIcon')
local BlockTeamName = Lua.import('Module:Widget/TeamDisplay/Component/BlockName')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class BlockTeamParameters
---@field name string?
---@field date number|string?
---@field teamTemplate teamTemplateData?
---@field additionalClasses string[]?
---@field overflow OverflowModes?
---@field flip boolean?
---@field noLink boolean?
---@field style teamStyle
---@field dq boolean?

---@class BlockTeamWidget: Widget
---@operator call(BlockTeamParameters): BlockTeamWidget
---@field name string?
---@field props BlockTeamParameters
---@field teamTemplate teamTemplateData
---@field flip boolean
---@field style teamStyle
local BlockTeamWidget = Class.new(Widget,
	---@param self self
	---@param input BlockTeamParameters
	function (self, input)
		self.teamTemplate = input.teamTemplate or TeamTemplate.getRawOrNil(input.name, input.date)
		self.name = (self.teamTemplate or {}).name or input.name
		self.flip = Logic.readBool(input.flip)
		self.style = input.style
	end
)

---@return Widget
function BlockTeamWidget:render()
	local teamTemplate = self.teamTemplate
	if not teamTemplate then
		mw.ext.TeamLiquidIntegration.add_category('Pages with missing team templates')
		return Div{
			classes = {'error'},
			children = TeamTemplate.noTeamMessage(self.name)
		}
	end
	local flip = self.flip

	local imageLight = Logic.emptyOr(teamTemplate.image, teamTemplate.legacyimage)
	local imageDark = Logic.emptyOr(teamTemplate.imagedark, teamTemplate.legacyimagedark)

	return Div{
		classes = Array.extend('block-team', self.props.additionalClasses, flip and 'flipped' or nil),
		children = WidgetUtil.collect(
			TeamIcon{
				imageLight = imageLight,
				imageDark = imageDark,
				page = teamTemplate.page,
				legacy = Logic.isEmpty(teamTemplate.image) and Logic.isNotEmpty(teamTemplate.legacyimage),
				noLink = self.props.noLink,
			},
			self:_getNameComponent()
		)
	}
end

---@private
---@return Widget|Widget[]?
function BlockTeamWidget:_getNameComponent()
	local style = self.style
	local displayName = self.teamTemplate.name
	local bracketName = self.teamTemplate.bracketname
	local shortName = self.teamTemplate.shortname
	local overflow = self.props.overflow or 'ellipsis'
	if style == 'standard' then
		return self:_createNameNode(displayName, overflow)
	elseif style == 'bracket' then
		return self:_createNameNode(bracketName, overflow)
	elseif style == 'short' then
		return self:_createNameNode(shortName, overflow)
	elseif style == 'hybrid' then
		return {
			self:_createNameNode(bracketName, 'ellipsis', {'hidden-xs'}),
			self:_createNameNode(shortName, 'hidden', {'visible-xs'})
		}
	end
end

---@private
---@param name string
---@param overflow OverflowModes
---@param additionalClasses string[]?
---@return BlockTeamNameDisplay
function BlockTeamWidget:_createNameNode(name, overflow, additionalClasses)
	return BlockTeamName{
		additionalClasses = additionalClasses,
		displayName = name,
		page = self.teamTemplate.page,
		noLink = self.props.noLink,
		overflowStyle = overflow,
		dq = self.props.dq,
	}
end

return BlockTeamWidget
