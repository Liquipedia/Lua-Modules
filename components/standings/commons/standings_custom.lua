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

local CustomStandings = Class.new(Standings)

---@param frame Frame
---@return Html
function CustomStandings.DisplayStanding(frame)
	local args = Arguments.getArgs(frame)
	return Standings.displayStandingFromLpdb(args)
end

---@param frame Frame
---@return Html
function CustomStandings.DisplayStageStandings(frame)
	local args = Arguments.getArgs(frame)
	return Standings.displayStageStandingsFromLpdb(args)
end

--[[
the 2 functions below would get added with step 3
]]

---@param frame Frame
---@return Html
function CustomStandings.GroupTableLeague(frame)
	local args = Arguments.getArgs(frame)
	-- possibly remap some alias stuff in wiki customs here if necessary
	return Standings(args):read():process():store():build()
end

---@param frame Frame
---@return Html
function CustomStandings.SwissTableLeague(frame)
	local args = Arguments.getArgs(frame)
	-- possibly remap some alias stuff in wiki customs here if necessary
	args.type = 'swiss'
	return Standings(args):read():read():process():store():build()
end

return CustomStandings
