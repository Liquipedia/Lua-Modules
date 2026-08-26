---
-- @Liquipedia
-- page=Module:Widget/TeamDisplay/Part
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local TeamIcon = Lua.import('Module:Widget/Image/Icon/TeamIcon')

---@class TeamPartParameters
---@field name string?
---@field date number|string?
---@field teamTemplate teamTemplateData?

---@param props TeamPartParameters
---@return VNode
local function TeamPartWidget(props)
	local teamTemplate = props.teamTemplate or TeamTemplate.getRawOrNil(props.name, props.date)
	if not teamTemplate then
		mw.ext.TeamLiquidIntegration.add_category('Pages with missing team templates')
		return Html.Small{
			classes = { 'error' },
			children = { TeamTemplate.noTeamMessage(props.name) }
		}
	end

	local imageLight = Logic.emptyOr(teamTemplate.image, teamTemplate.legacyimage)
	local imageDark = Logic.emptyOr(teamTemplate.imagedark, teamTemplate.legacyimagedark)

	return Div{
		attributes = { ['data-highlighting-class'] = teamTemplate.name },
		classes = {'team-template-team-part'},
		children = TeamIcon{
			imageLight = imageLight,
			imageDark = imageDark,
			name = teamTemplate.name,
			page = teamTemplate.page,
			legacy = Logic.isEmpty(teamTemplate.image) and Logic.isNotEmpty(teamTemplate.legacyimage),
			noLink = teamTemplate.page == 'TBD',
		}
	}
end

return Component.component(TeamPartWidget)
