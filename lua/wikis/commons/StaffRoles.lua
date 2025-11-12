---
-- @Liquipedia
-- page=Module:StaffRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type table<string, PersonRoleData>
local staffRoles = {
	['admin'] = {category = 'Admins', display = 'Admin'},
	['analyst'] = {category = 'Analysts', display = 'Analyst'},
	['broadcast analyst'] = {category = 'Broadcast Analysts', display = 'Broadcast Analyst'},
	['caster'] = {category = 'Casters', display = 'Caster'},
	['assistant coach'] = {category = 'Coaches', display = 'Assistant Coach'},
	['coach'] = {category = 'Coaches', display = 'Coach'},
	['head coach'] = {category = 'Coaches', display = 'Head Coach'},
	['positional coach'] = {category = 'Coaches', display = 'Positional Coach'},
	['strategic coach'] = {category = 'Coaches', display = 'Strategic Coach'},
	['creator'] = {category = 'Content Creators', display = 'Content Creator'},
	['expert'] = {category = 'Experts', display = 'Expert'},
	['host'] = {category = 'Hosts', display = 'Host'},
	['interviewer'] = {category = 'Interviewers', display = 'Interviewer'},
	['journalist'] = {category = 'Journalists', display = 'Journalist'},
	['manager'] = {category = 'Managers', display = 'Manager'},
	['map maker'] = {category = 'Map makers', display = 'Map maker'},
	['observer'] = {category = 'Observers', display = 'Observer'},
	['director of esport'] = {category = 'Organizational Staff', display = 'Director of Esport'},
	['executive'] = {category = 'Organizational Staff', display = 'Executive'},
	['photographer'] = {category = 'Photographers', display = 'Photographer'},
	['director'] = {category = 'Production Staff', display = 'Director'},
	['interpreter'] = {category = 'Production Staff', display = 'Interpreter'},
	['producer'] = {category = 'Production Staff', display = 'Producer'},
	['replay operator'] = {category = 'Production Staff', display = 'Replay Operator'},
	['stats producer'] = {category = 'Production Staff', display = 'Stats Producer'},
	['translator'] = {category = 'Production Staff', display = 'Translator'},
	['streamer'] = {category = 'Streamers', display = 'Streamer'},
	['talent'] = {category = 'Talents', display = 'Talent'},
	['organizer'] = {category = 'Tournament Organizer', display = 'Tournament Organizer'},
	['staff'] = {category = 'Staff', display = 'Staff'},
	['referee'] = {category = 'Referees', display = 'Referee'},
}

staffRoles['commentator'] = staffRoles['caster']
staffRoles['tournament organizer'] = staffRoles['organizer']
staffRoles['content producer'] = staffRoles['content creator']
staffRoles['content creator'] = staffRoles.creator
staffRoles['content'] = staffRoles.creator
staffRoles.to = staffRoles.organizer
staffRoles['asst. coach'] = staffRoles['assistant coach']
staffRoles['mapper'] = staffRoles['map maker']

return staffRoles
