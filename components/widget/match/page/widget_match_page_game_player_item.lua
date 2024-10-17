---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game/Item
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class MatchPageHeaderGameItem: Widget
---@operator call(table): MatchPageHeaderGameItem
local MatchPageHeaderGameItem = Class.new(Widget)

---@return string
function MatchPageHeaderGameItem:render()
	if Logic.isEmpty(self.props.name) then
		return '[[File:EmptyIcon itemicon dota2 gameasset.png|64px|Empty|link=]]'
	end
	return '[[File:'.. self.props.image ..'|64px|'.. self.props.name ..'|link=]]'
end

return MatchPageHeaderGameItem
