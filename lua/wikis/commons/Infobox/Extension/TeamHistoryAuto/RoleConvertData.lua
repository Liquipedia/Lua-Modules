---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Extension/TeamHistoryAuto/RoleConvertData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	coach = {title = 'Coach', children = {'C.'}},
	analyst = {title = 'Analyst', children = {'A.'}},
	['head coach'] = {title = 'Coach', children = {'C.'}},
	['assistant coach'] = {title = 'Assistant Coach', children = {'AC.'}},
	['coach/analyst'] = {title = 'Coach/Analyst', children = {'C./A.'}},
	['coach and analyst'] = {title = 'Coach/Analyst', children = {'C./A.'}},
	['manager and analyst'] = {title = 'Manager/Analyst', children = {'M./A.'}},
	['manager/analyst'] = {title = 'Manager/Analyst', children = {'M./A.'}},
	manager = {title = 'Manager', children = {'M.'}},
	['general manager'] = {title = 'General Manager', children = {'GM.'}},
	['assistant general manager'] = {title = 'Assistant General Manager', children = {'AGM.'}},
	['team manager'] = {title = 'Team Manager', children = {'TM.'}},
	['assistant team manager'] = {title = 'Assistant Team Manager', children = {'ATM.'}},
	translator = {title = 'Translator', children = {'T.'}},
	substitute = {title = 'Substitute', children = {'Sub.'}},
	streamer = {title = 'Streamer', children = {'Str.'}},
	['content creator'] = {title = 'Content Creator', children = {'CC.'}},
	inactive = {title = 'Inactive', children = {'Ia.'}},
	loan = {title = 'Loan', children = {'L.'}},
}
