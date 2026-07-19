---
-- @Liquipedia
-- page=Module:Infobox/Extension/Nation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Nation = {}

local NATIONS = {
	germany = {name = 'Germany', flag = 'WoT NationFlag Germany.png'},
	ussr = {name = 'U.S.S.R.', flag = 'WoT NationFlag USSR.png'},
	usa = {name = 'U.S.A', flag = 'WoT NationFlag USA.png'},
	china = {name = 'China', flag = 'WoT NationFlag China.png'},
	france = {name = 'France', flag = 'WoT NationFlag France.png'},
	uk = {name = 'U.K.', flag = 'WoT NationFlag UK.png'},
	japan = {name = 'Japan', flag = 'WoT NationFlag Japan.png'},
	czechoslovakia = {name = 'Czechoslovakia', flag = 'WoT NationFlag Czechoslovakia.png'},
	sweden = {name = 'Sweden', flag = 'WoT NationFlag Sweden.png'},
	poland = {name = 'Poland', flag = 'WoT NationFlag Poland.png'},
	italy = {name = 'Italy', flag = 'WoT NationFlag Italy.png'},
}

---@param nation string?
---@return string?
function Nation.run(nation)
	if not nation or type(nation) ~= 'string' then
		return
	end

	local nationKey = mw.text.trim(nation:lower():gsub('%.', ''))
	local nationData = NATIONS[nationKey]

	if not nationData then
		return
	end

	return '[[File:' .. nationData.flag .. '|link=|18x14px|' .. nationData.name .. ']]' .. '&nbsp;' .. nationData.name
end

return Nation
