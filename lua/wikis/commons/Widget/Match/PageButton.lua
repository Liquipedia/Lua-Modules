---
-- @Liquipedia
-- page=Module:Widget/Match/PageButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local I18n = Lua.import('Module:I18n')
local Logic = Lua.import('Module:Logic')

local Info = Lua.import('Module:Info', {loadData = true})
local Widget = Lua.import('Module:Widget')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')
local MatchUtil = Lua.import('Module:Match/Util')

---@class MatchPageButtonProps
---@field match MatchGroupUtilMatch
---@field buttonType 'secondary' | 'ghost'
---@field buttonText 'full' | 'short' | 'hide'

---@class MatchPageButton: Widget
---@operator call(MatchPageButtonProps): MatchPageButton
---@field props MatchPageButtonProps
local MatchPageButton = Class.new(Widget)
MatchPageButton.defaultProps = {
	buttonType = 'secondary',
	buttonText = 'full',
}

---@return Widget?
function MatchPageButton:render()
	if not Info.config.match2.matchPage then
		return nil
	end
	local match = self.props.match
	if not match then
		return nil
	end

	local showMatchDetails = MatchUtil.shouldShowMatchDetails(match)

	-- Original Match Id must be used to link match page if it exists.
	-- It can be different from the matchId when shortened brackets are used.
	local matchId = match.extradata.originalmatchid or match.matchId

	local link = 'Match:ID ' .. matchId

	if Logic.isNotEmpty(match.bracketData.matchPage) then
		return Button{
			classes = { 'match-page-button', (not showMatchDetails) and 'show-when-logged-in' or nil},
			title = 'View match details',
			variant = self.props.buttonType,
			size = 'sm',
			link = link,
			grow = true,
			children = WidgetUtil.collect(
				Icon{iconName = 'matchpagelink'},
				self.props.buttonText == 'full' and ' ' .. I18n.translate('matchdetails-view-long') or nil,
				self.props.buttonText == 'short' and ' ' .. I18n.translate('matchdetails-short') or nil
			)
		}
	end

	return Button{
		classes = { 'match-page-button', 'show-when-logged-in' },
		title = 'Make match page',
		variant = 'ghost',
		size = 'sm',
		link = link,
		grow = true,
		children = WidgetUtil.collect(
			'+',
			self.props.buttonText == 'full' and ' ' .. I18n.translate('matchdetails-add-long') or nil,
			self.props.buttonText == 'short' and ' ' ..  I18n.translate('matchdetails-short') or nil
		)
	}
end

return MatchPageButton
