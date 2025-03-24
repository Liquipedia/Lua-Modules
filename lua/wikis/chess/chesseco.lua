---
-- @Liquipedia
-- wiki=chess
-- page=Module:ChessEco
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')

local ChessOpening = mw.loadData('Module:ChessEco/Data')

local ChessEcoSetup = {}

function ChessEcoSetup.sanitise(eco)
	if Logic.isEmpty(eco) then
		return
	end
	eco = mw.text.trim(eco):upper()
	if ChessOpening[eco] then
		return eco
	end
end

function ChessEcoSetup.getName(eco, withPrefix)
	eco = ChessEcoSetup.sanitise(eco)
	if ChessOpening[eco] then
		return withPrefix and (eco .. ': ' .. ChessOpening[eco]) or ChessOpening[eco]
	end
end

return ChessEcoSetup
