---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Characters
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Character = Lua.import('Module:Widget/Match/Summary/Character')

local BASE_SIZE = 24 -- From brkts-champion-icon in Brackets.less
local HOVER_MODIFIER = 2.5 -- From brkts-champion-icon in Brackets.less

---@class MatchSummaryCharactersProps
---@field flipped boolean?
---@field characters string[]?
---@field hideOnMobile boolean?
---@field bg string?
---@field date string?
---@field size integer?
---@field css table<string, string|number?>?

local defaultProps = {
	flipped = false,
	hideOnMobile = false,
	size = BASE_SIZE * HOVER_MODIFIER,
}

---@param props MatchSummaryCharactersProps
---@return Widget[]?
local function MatchSummaryCharacters(props)
	if not props.characters then
		return nil
	end
	local flipped = props.flipped

	return Div{
		classes = Array.extend(
			'brkts-popup-body-element-thumbs',
			'brkts-champion-icon',
			flipped and 'brkts-popup-body-element-thumbs-right' or nil,
			props.hideOnMobile and 'mobile-hide' or nil
		),
		css = props.css,
		children = Array.map(props.characters, function(character)
			return Character{
				character = character,
				date = props.date,
				bg = props.bg,
				showName = #props.characters == 1,
				flipped = flipped,
				size = props.size .. 'px',
			}
		end)
	}
end

return Component.component(MatchSummaryCharacters, defaultProps)
