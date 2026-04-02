---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class AbstractGameTiebreaker : StandingsTiebreaker
local AbstractGameTiebreaker = Class.new(TiebreakerInterface)

---@protected
---@param self AbstractGameTiebreaker
---@return number
AbstractGameTiebreaker.getWalkoverCoefficient = FnUtil.memoize(function (self)
	local config = self.config
	if not config then
		return 0
	end
	return tonumber(config.walkover) or 0
end)

---@protected
---@return boolean
function AbstractGameTiebreaker:isWalkoverCoefficientDefined()
	return self:getWalkoverCoefficient() > 0
end

---@protected
---@param walkover {w: integer?, l: integer?}?
---@return {w: integer, l: integer}
function AbstractGameTiebreaker:calculateWalkoverValues(walkover)
	if not self:isWalkoverCoefficientDefined() or not walkover then
		return {w = 0, l = 0}
	end

	local walkoverCoefficient = self:getWalkoverCoefficient()

	return {
		w = (walkover.w or 0) * walkoverCoefficient,
		l = (walkover.l or 0) * walkoverCoefficient
	}
end

return AbstractGameTiebreaker
