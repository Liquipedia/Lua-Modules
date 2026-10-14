---
-- @Liquipedia
-- page=Module:Features/QualificationChances/Api/Fetch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Fetch = {}

function Fetch.fromWikiJson(pagename)
	return mw.loadJsonData(pagename)
end

return Fetch
