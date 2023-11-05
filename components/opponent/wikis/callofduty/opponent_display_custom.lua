---
-- @Liquipedia
-- wiki=callofduty
-- page=Module:OpponentDisplay/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DisplayUtil = require('Module:DisplayUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})
local PlayerDisplay = Lua.import('Module:Player/Display', {requireDevIfEnabled = true})

---Display components for opponents used by the COD wiki
---@class CallOfDutyOpponentDisplay: OpponentDisplay
local CustomOpponentDisplay = Table.copy(OpponentDisplay)

---Displays an opponent as an inline element. Useful for describing opponents in prose.
---@param props InlineOpponentProps
---@return Html|string|nil
function CustomOpponentDisplay.InlineOpponent(props)
	local opponent = props.opponent

	if Opponent.typeIsParty(opponent.type) then
		return OpponentDisplay.InlinePlayers(props)(props)
	end

	 return OpponentDisplay.InlineOpponent(props)
end

--[[
Displays an opponent as a block element. The width of the component is
determined by its layout context, and not of the opponent.
]]
---@param props BlockOpponentProps
---@return Html
function CustomOpponentDisplay.BlockOpponent(props)
	local opponent = props.opponent
	-- Default TBDs to not show links
	local showLink = Logic.nilOr(props.showLink, not Opponent.isTbd(opponent))

	if Opponent.typeIsParty(opponent.type) then
		return OpponentDisplay.BlockPlayers(Table.merge(props, {showLink = showLink}))
	end

	return OpponentDisplay.BlockOpponent(props)
end

return CustomOpponentDisplay
