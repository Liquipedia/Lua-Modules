---
-- @Liquipedia
-- page=Module:Widget/TeamDisplay/Inline
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Span = Html.Span
local TeamIcon = Lua.import('Module:Widget/Image/Icon/TeamIcon')
local TeamName = Lua.import('Module:Widget/TeamDisplay/Component/Name')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class InlineType
---@field displayType string
---@field displayNames table<string, string[]>

---@type table<teamStyle, InlineType>
local TEAM_INLINE_TYPES = {
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
	},
	['hybrid'] = {
		displayType = 'standard',
		displayNames = {
			['bracketname'] = {'mobile-hide'},
			['shortname'] = {'mobile-only'}
		}
	}
}

---@class TeamInlineParameters
---@field name string?
---@field date number|string?
---@field teamTemplate teamTemplateData?
---@field flip boolean?
---@field displayType teamStyle

local TeamInlineWidget = {}

---@param props TeamInlineParameters
---@return teamTemplateData?
function TeamInlineWidget.readTeamTemplate(props)
	if props.teamTemplate then
		return props.teamTemplate
	end
	return TeamTemplate.getRawOrNil(props.name, props.date)
end

---@param props TeamInlineParameters
---@return VNode
function TeamInlineWidget.render(props)
	local displayType = assert(TEAM_INLINE_TYPES[props.displayType], 'Invalid display type')
	local teamTemplate = props.teamTemplate or TeamTemplate.getRawOrNil(props.name, props.date)
	if not teamTemplate then
		mw.ext.TeamLiquidIntegration.add_category('Pages with missing team templates')
		return Html.Small{
			classes = { 'error' },
			children = { TeamTemplate.noTeamMessage(props.name) }
		}
	end
	local flip = Logic.readBool(props.flip)
	local imageLight = Logic.emptyOr(teamTemplate.image, teamTemplate.legacyimage)
	local imageDark = Logic.emptyOr(teamTemplate.imagedark, teamTemplate.legacyimagedark)
	local children = Array.interleave(WidgetUtil.collect(
		TeamIcon{
			imageLight = imageLight,
			imageDark = imageDark,
			name = teamTemplate.name,
			page = teamTemplate.page,
			legacy = Logic.isEmpty(teamTemplate.image) and Logic.isNotEmpty(teamTemplate.legacyimage),
			noLink = teamTemplate.page == 'TBD',
		},
		TeamInlineWidget._getNameComponent(displayType, teamTemplate)
	), ' ')
	return Span{
		attributes = { ['data-highlighting-class'] = teamTemplate.name },
		classes = { 'team-template-team' .. (flip and '2' or '') .. '-' .. displayType.displayType },
		children = flip and Array.reverse(children) or children
	}
end

---@private
---@param displayType InlineType
---@param teamTemplate teamTemplateData
---@return VNode
function TeamInlineWidget._getNameComponent(displayType, teamTemplate)
	return Html.Fragment{
		children = Array.map(Table.entries(displayType.displayNames), function (element)
			return TeamName{
				additionalClasses = element[2],
				displayName = teamTemplate[element[1]],
				page = teamTemplate.page,
				noLink = teamTemplate.page == 'TBD',
			}
		end)
	}
end

return Component.component(TeamInlineWidget.render)
