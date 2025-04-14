---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Infobox/Extension/TeamHistoryAuto/RoleConvertData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	coach = {title = 'Coach', children = {'C.'}},
	analyst = {title = 'Analyst', children = {'A.'}},
	['head coach'] = {title = 'Coach', children = {'C.'}},
	['coach/analyst'] = {title = 'Coach/Analyst', children = {'C./A.'}},
	['coach and analyst'] = {title = 'Coach/Analyst', children = {'C./A.'}},
	manager = {title = 'Manager', children = {'M.'}},
	substitute = {title = 'Substitute', children = {'Sub.'}},
	streamer = {title = 'Streamer', children = {'Str.'}},

	top = {isEmpty = true},
	jungle = {isEmpty = true},
	mid = {isEmpty = true},
	adc = {isEmpty = true},
	bot = {isEmpty = true},
	support = {isEmpty = true},
}
