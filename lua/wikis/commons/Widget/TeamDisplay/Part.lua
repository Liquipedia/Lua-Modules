---
-- @Liquipedia
-- page=Module:Widget/TeamDisplay/Part
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local TeamIcon = Lua.import('Module:Widget/Image/Icon/TeamIcon')

---@class TeamPartParameters
---@field name string?
---@field date number|string?
---@field teamTemplate teamTemplateData?

---@class TeamPartWidget: Widget
---@operator call(TeamPartParameters): TeamPartWidget
---@field name string?
---@field props TeamPartParameters
---@field teamTemplate teamTemplateData
---@field flip boolean
---@field displayType InlineType
local TeamPartWidget = Class.new(Widget,
	---@param self self
	---@param input TeamPartParameters
	function (self, input)
		self.teamTemplate = input.teamTemplate or TeamTemplate.getRawOrNil(input.name, input.date)
		self.name = (self.teamTemplate or {}).name or input.name
	end
)

---@return Widget
function TeamPartWidget:render()
	local teamTemplate = self.teamTemplate
	if not teamTemplate then
		mw.ext.TeamLiquidIntegration.add_category('Pages with missing team templates')
		return HtmlWidgets.Small{
			classes = { 'error' },
			children = { TeamTemplate.noTeamMessage(self.name) }
		}
	end

	local imageLight = Logic.emptyOr(teamTemplate.image, teamTemplate.legacyimage)
	local imageDark = Logic.emptyOr(teamTemplate.imagedark, teamTemplate.legacyimagedark)

	return Div{
		attributes = { ['data-highlighting-class'] = self.teamTemplate.name },
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

return TeamPartWidget
