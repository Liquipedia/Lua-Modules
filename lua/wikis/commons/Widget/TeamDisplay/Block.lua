---
-- @Liquipedia
-- page=Module:Widget/TeamDisplay/Block
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
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
---@field note string|number?

local BlockTeamWidget = {}

---@param props BlockTeamParameters
---@return teamTemplateData?
function BlockTeamWidget.readTeamTemplate(props)
	if props.teamTemplate then
		return props.teamTemplate
	end
	return TeamTemplate.getRawOrNil(props.name, props.date)
end

---@param props BlockTeamParameters
function BlockTeamWidget.render(props)
	local teamTemplate = props.teamTemplate or TeamTemplate.getRawOrNil(props.name, props.date)

	if not teamTemplate then
		mw.ext.TeamLiquidIntegration.add_category('Pages with missing team templates')
		return Div{
			classes = {'error'},
			children = TeamTemplate.noTeamMessage(props.name)
		}
	end

	local flip = Logic.readBool(props.flip)

	local imageLight = Logic.emptyOr(teamTemplate.image, teamTemplate.legacyimage)
	local imageDark = Logic.emptyOr(teamTemplate.imagedark, teamTemplate.legacyimagedark)

	return Div{
		classes = Array.extend('block-team', props.additionalClasses, flip and 'flipped' or nil),
		children = WidgetUtil.collect(
			TeamIcon{
				imageLight = imageLight,
				imageDark = imageDark,
				page = teamTemplate.page,
				legacy = Logic.isEmpty(teamTemplate.image) and Logic.isNotEmpty(teamTemplate.legacyimage),
				noLink = props.noLink,
			},
			BlockTeamWidget._getNameComponent(teamTemplate, props),
			Logic.isNotEmpty(props.note) and Html.Sup{
				classes = {'note'},
				children = props.note
			} or nil
		)
	}
end

---@private
---@param teamTemplate teamTemplateData
---@param props BlockTeamParameters
---@return VNode|VNode[]?
function BlockTeamWidget._getNameComponent(teamTemplate, props)
	local name = teamTemplate.name
	local bracketName = teamTemplate.bracketname
	local shortName = teamTemplate.shortname
	local style = props.style

	---@param displayName string
	---@param overflow OverflowModes?
	---@param additionalClasses string[]?
	---@return VNode
	local function createNameNode(displayName, overflow, additionalClasses)
		return BlockTeamName{
			additionalClasses = additionalClasses,
			displayName = displayName,
			page = teamTemplate.page,
			noLink = props.noLink,
			overflowStyle = overflow or props.overflow,
			dq = props.dq,
		}
	end

	if style == 'standard' then
		return createNameNode(name)
	elseif style == 'bracket' then
		return createNameNode(bracketName)
	elseif style == 'short' then
		return createNameNode(shortName)
	elseif style == 'hybrid' then
		return {
			createNameNode(bracketName, 'ellipsis', {'hidden-xs'}),
			createNameNode(shortName, 'hidden', {'visible-xs'})
		}
	end
end

return Component.component(BlockTeamWidget.render)
