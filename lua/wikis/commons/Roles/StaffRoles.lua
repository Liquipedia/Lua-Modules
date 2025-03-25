---
-- @Liquipedia
-- wiki=commons
-- page=Module:StaffRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local staffRoles = {
	['analyst'] = {category = 'Analysts', display = 'Analyst'},
	['broadcast analyst'] = {category = 'Broadcast Analysts', display = 'Broadcast Analyst'},
	['observer'] = {category = 'Observers', display = 'Observer'},
	['host'] = {category = 'Hosts', display = 'Host'},
	['journalist'] = {category = 'Journalists', display = 'Journalist'},
	['expert'] = {category = 'Experts', display = 'Expert'},
	['producer'] = {category = 'Production Staff', display = 'Producer'},
	['director'] = {category = 'Production Staff', display = 'Director'},
	['executive'] = {category = 'Organizational Staff', display = 'Executive'},
	['coach'] = {category = 'Coaches', display = 'Coach'},
	['assistant coach'] = {category = 'Coaches', display = 'Assistant Coach'},
	['manager'] = {category = 'Managers', display = 'Manager'},
	['director of esport'] = {category = 'Organizational Staff', display = 'Director of Esport'},
	['caster'] = {category = 'Casters', display = 'Caster'},
	['streamer'] = {category = 'Streamers', variable = 'Streamer'},
	['content creator'] = {category = 'Content Creators', variable = 'Content Creator'},
	['stats producer'] = {category = 'Production Staff', variable = 'Stats Producer'},
	['interviewer'] = {category = 'Interviewers', variable = 'Interviewer'},
	['translator'] = {category = 'Production Staff', variable = 'Translator'},
	['interpreter'] = {category = 'Production Staff', variable = 'Interpreter'},
}

return staffRoles
