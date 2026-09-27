---
-- @Liquipedia
-- page=Module:Features/Squad/LegacyAdaptor
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local SquadTypes = Lua.import('Module:Features/Squad/Types')

local LegacySquadAdaptor = {}

function LegacySquadAdaptor.adapt(args)
	-- Legacy mode: Call old SquadAuto
	local OldSquadAuto = Lua.import('Module:SquadAuto')

	local type = SquadTypes.TypeToSquadType[(args.type or ''):lower()]
	-- Old module needs special type argument
	if type == SquadTypes.SquadType.STAFF then
		args.type = 'Organization_' .. args.status
	else
		args.type = 'Player_' .. args.status
	end

	return OldSquadAuto[args.status](args)
end

return LegacySquadAdaptor
