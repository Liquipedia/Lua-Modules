---
-- @Liquipedia
-- page=Module:VehiclePool
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local p = {}

function p.main(frame)
	local args = frame:getParent().args

	local output = ''

	-- Simple loop to find vehicles
	local i = 1
	while args['vehicle' .. i] do
		if i > 1 then
			output = output .. ' • '
		end

		local vehicle = args['vehicle' .. i]
		local vehicleType = args['vehicle' .. i .. 'type']

		if vehicleType then
			output = output .. '[[' .. vehicle .. ']] (' .. vehicleType .. ')'
		else
			output = output .. '[[' .. vehicle .. ']]'
		end

		i = i + 1
	end

	if output == '' then
		return 'No vehicles found'
	end

	return output
end

return p