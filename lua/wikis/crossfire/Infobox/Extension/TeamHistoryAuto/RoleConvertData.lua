---
-- @Liquipedia
-- wiki=crossfire
-- page=Module:Infobox/Extension/TeamHistoryAuto/RoleConvertData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	coach = {title = 'Coach', children = {'C.'}},
	analyst = {title = 'Analyst', children = {'A.'}},
	['head coach'] = {title = 'Coach', children = {'HC.'}},
	['assistant coach'] = {title = 'Assistant Coach', children = {'AC.'}},
	['overall coach'] = {title = 'Overall Coach', children = {'OC.'}},
	loan = {title = 'Loan', children = {'L.'}},
	substitute = {title = 'Substitute', children = {'Sub.'}},
	inactive = {title = 'Inactive', children = {'Ia.'}},
	manager = {title = 'Manager', children = {'M.'}},
	['general manager'] = {title = 'General Manager', children = {'GM.'}},
	streamer = {title = 'Streamer', children = {'Str.'}},
	['content creator'] = {title = 'Content Creator', children = {'CC.'}},
	['training director'] = {title = 'Training Director', children = {'TD.'}},
	['training advisor'] = {title = 'Training Advisor', children = {'TA.'}},
	['founder & training director'] = {title = 'Founder & Training Director', children = {'F. & TD.'}},
}
