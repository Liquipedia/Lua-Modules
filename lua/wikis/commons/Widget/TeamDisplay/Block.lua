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

---@class BlockTeamParsedProps
---@field name string?
---@field props BlockTeamParameters
---@field teamTemplate teamTemplateData
---@field flip boolean
---@field style teamStyle

local BlockTeamWidget = {}

local Helpers = {}

function BlockTeamWidget.render(props)
	local parsedProps = Helpers.parse(props)

	local teamTemplate = parsedProps.teamTemplate
	if not teamTemplate then
		mw.ext.TeamLiquidIntegration.add_category('Pages with missing team templates')
		return Div{
			classes = {'error'},
			children = TeamTemplate.noTeamMessage(parsedProps.name)
		}
	end
	local flip = parsedProps.flip

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
			Helpers._getNameComponent(parsedProps),
			Logic.isNotEmpty(props.note) and Html.Sup{
				classes = {'note'},
				children = props.note
			} or nil
		)
	}
end

---@param props BlockTeamParameters
---@return BlockTeamParsedProps
function Helpers.parse(props)
	local parsedProps = {props = props}

	parsedProps.teamTemplate = props.teamTemplate or TeamTemplate.getRawOrNil(props.name, props.date)
	parsedProps.name = (parsedProps.teamTemplate or {}).name or props.name
	parsedProps.flip = Logic.readBool(props.flip)
	parsedProps.style = props.style

	return parsedProps
end

---@private
---@param props BlockTeamParsedProps
---@return Widget|Widget[]?
function Helpers._getNameComponent(props)
	local style = props.style
	local displayName = props.teamTemplate.name
	local bracketName = props.teamTemplate.bracketname
	local shortName = props.teamTemplate.shortname
	local overflow = props.props.overflow or 'ellipsis'
	if style == 'standard' then
		return Helpers._createNameNode(props, displayName, overflow)
	elseif style == 'bracket' then
		return Helpers._createNameNode(props, bracketName, overflow)
	elseif style == 'short' then
		return Helpers._createNameNode(props, shortName, overflow)
	elseif style == 'hybrid' then
		return {
			Helpers._createNameNode(props, bracketName, 'ellipsis', {'hidden-xs'}),
			Helpers._createNameNode(props, shortName, 'hidden', {'visible-xs'})
		}
	end
end

---@private
---@param props BlockTeamParsedProps
---@param name string
---@param overflow OverflowModes
---@param additionalClasses string[]?
---@return Widget
function Helpers._createNameNode(props, name, overflow, additionalClasses)
	return BlockTeamName{
		additionalClasses = additionalClasses,
		displayName = name,
		page = props.teamTemplate.page,
		noLink = props.props.noLink,
		overflowStyle = overflow,
		dq = props.props.dq,
	}
end

return Component.component(BlockTeamWidget.render)
