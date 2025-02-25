---
-- @Liquipedia
-- wiki=chess
-- page=Module:Chess/ECO
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')

local _ECO = mw.loadData('Module:Chess/ECO/Data')

local p = {}

function p.sanitise(eco)
	if Logic.isEmpty(eco) then
		return
	end
	eco = mw.text.trim(eco):upper()
	if _ECO[eco] then
		return eco
	end
end

function p.getName(eco, withPrefix)
	eco = p.sanitise(eco)
	if _ECO[eco] then
		return withPrefix and (eco .. ': ' .. _ECO[eco]) or _ECO[eco]
	end
end

return p
