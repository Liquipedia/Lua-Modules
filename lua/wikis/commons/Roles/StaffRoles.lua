---
-- @Liquipedia
-- wiki=commons
-- page=Module:StaffRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local staffRoles = {
	['analyst'] = {category = 'Analysts', display = 'Analyst', coach = true},
	['broadcast analyst'] = {category = 'Broadcast Analysts', display = 'Broadcast Analyst', talent = true},
	['observer'] = {category = 'Observers', display = 'Observer', talent = true},
	['host'] = {category = 'Hosts', display = 'Host', talent = true},
	['journalist'] = {category = 'Journalists', display = 'Journalist', talent = true},
	['expert'] = {category = 'Experts', display = 'Expert', talent = true},
	['producer'] = {category = 'Production Staff', display = 'Producer', talent = true},
	['director'] = {category = 'Production Staff', display = 'Director', talent = true},
	['executive'] = {category = 'Organizational Staff', display = 'Executive', management = true},
	['coach'] = {category = 'Coaches', display = 'Coach', coach = true},
	['assistant coach'] = {category = 'Coaches', display = 'Assistant Coach', coach = true},
	['manager'] = {category = 'Managers', display = 'Manager', management = true},
	['director of esport'] = {category = 'Organizational Staff', display = 'Director of Esport', management = true},
	['caster'] = {category = 'Casters', display = 'Caster', talent = true},
}

return staffRoles
