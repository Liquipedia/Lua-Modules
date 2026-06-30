---
-- @Liquipedia
-- page=Module:Widget/Match/PageButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local I18n = Lua.import('Module:I18n')
local Logic = Lua.import('Module:Logic')

local Info = Lua.import('Module:Info', {loadData = true})
local Component = Lua.import('Module:Widget/Component')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')
local MatchUtil = Lua.import('Module:Match/Util')

---@class MatchPageButtonProps
---@field match MatchGroupUtilMatch
---@field buttonType? 'secondary'|'ghost'
---@field buttonText? 'full'|'short'|'hide'

local defaultProps = {
	buttonType = 'secondary',
	buttonText = 'full',
}

---@param props MatchPageButtonProps
---@return VNode?
local function MatchPageButton(props)
	if not Info.config.match2.matchPage then
		return nil
	end
	local match = props.match
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
			variant = props.buttonType,
			size = 'sm',
			link = link,
			grow = true,
			children = WidgetUtil.collect(
				Icon{iconName = 'matchpagelink'},
				props.buttonText == 'full' and ' ' .. I18n.translate('matchdetails-view-long') or nil,
				props.buttonText == 'short' and ' ' .. I18n.translate('matchdetails-short') or nil
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
			props.buttonText == 'full' and ' ' .. I18n.translate('matchdetails-add-long') or nil,
			props.buttonText == 'short' and ' ' .. I18n.translate('matchdetails-short') or nil
		)
	}
end

return Component.component(MatchPageButton, defaultProps)
