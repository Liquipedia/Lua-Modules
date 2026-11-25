---
-- @Liquipedia
-- page=Module:PlayerTournamentAppearances
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- to be nuked after bot conversion runs

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Table = Lua.import('Module:Table')

local New = Lua.import('Module:Features/TournamentAppearances/Custom')

local Legacy = {run = New.run}

---@param frame Frame
---@return string
function Legacy.convert(frame)
	local args = Legacy._convertArgs(frame)

	local argsInput = {}
	for key, item in pairs(args) do
		table.insert(argsInput, '|' .. key .. '=' .. item)
	end

	return '{{PlayerTournamentAppearances' .. table.concat(argsInput) .. '}}'
end

---@param frame Frame
---@return Renderable
function Legacy.run(frame)
	return New.run(Legacy._convertArgs(frame))
end

---@param frame Frame
---@return table<string, string>
function Legacy._convertArgs(frame)
	local args = Arguments.getArgs(frame)

	-- convert series to csv
	local seriesArgs = Table.filterByKey(args, function(key) return key:find('^series%d-$') end)
	local series = Array.extractValues(seriesArgs)
	for key in pairs(seriesArgs) do
		args[key] = nil
	end
	args.series = table.concat(series, ',')

	-- convert `|playerspage=`
	args.restrictToPlayersParticipatingIn = args.playerspage
	args.playerspage = nil

	return args
end

return Legacy
