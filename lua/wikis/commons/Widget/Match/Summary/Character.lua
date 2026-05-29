---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Character
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class MatchSummaryCharacterProps: IconArguments
---@field showName boolean?
---@field flipped boolean?
---@field bg string?

local defaultProps = {
	showName = false,
	flipped = false,
}

---@param props MatchSummaryCharacterProps
---@return Widget[]?
local function MatchSummaryCharacter(props)
	local characterIcon = CharacterIcon.Icon{
		character = props.character,
		date = props.date,
		size = props.size
	}
	local children = { characterIcon }
	if props.showName then
		children = {characterIcon, ' ', props.character}
	end

	return Div{
		classes = {props.bg},
		children = props.flipped and Array.reverse(children) or children
	}
end

return Component.component(MatchSummaryCharacter, defaultProps)
