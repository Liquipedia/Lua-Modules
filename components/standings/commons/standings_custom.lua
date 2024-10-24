---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Standings = Lua.import('Module:Standings/Base')

---@class CustomStandings: BaseStandings
local CustomStandings = Class.new(Standings)

---@param frame Frame
---@return Html
function CustomStandings.DisplayStanding(frame)
	local args = Arguments.getArgs(frame)
	return CustomStandings.displayStandingFromLpdb(args)
end

---@param frame Frame
---@return Html
function CustomStandings.DisplayStageStandings(frame)
	local args = Arguments.getArgs(frame)
	return CustomStandings.displayStageStandingsFromLpdb(args)
end

--[[
below would get added with step 3
]]

---@param frame Frame
---@return Html
function CustomStandings.GroupTableLeague(frame)
	local args = Arguments.getArgs(frame)
	return CustomStandings.run(args)
end

---@param frame Frame
---@return Html
function CustomStandings.SwissTableLeague(frame)
	local args = Arguments.getArgs(frame)
	args.type = 'swiss'
	return CustomStandings.run(args)
end

---@param args table
---@return Html
function CustomStandings.run(args)
	return CustomStandings(args):read():process():store():build()
end

return CustomStandings
