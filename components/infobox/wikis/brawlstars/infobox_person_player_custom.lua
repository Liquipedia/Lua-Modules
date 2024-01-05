---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local PlayerIntroduction = require('Module:PlayerIntroduction')
local String = require('Module:StringUtils')
local Team = require('Module:Team')
local Variables = require('Module:Variables')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _ROLES = {
	-- staff
	coach = {category = 'Coaches', variable = 'Coach', isplayer = false, personType = 'staff'},
	manager = {category = 'Manager', variable = 'Manager', isplayer = false, personType = 'staff'},

	-- talent
	analyst = {category = 'Analysts', variable = 'Analyst', isplayer = false, personType = 'talent'},
	caster = {category = 'Casters', variable = 'Caster', isplayer = false, personType = 'talent'},
	['content creator'] = {
		category = 'Content Creators', variable = 'Content Creator', isplayer = false, personType = 'talent'},
	host = {category = 'Host', variable = 'Host', isplayer = false, personType = 'talent'},
}
_ROLES['assistant coach'] = _ROLES.coach
_ROLES.commentator = _ROLES.caster

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	player.roleData = CustomPlayer._getRole(player.args.role) or {}
	player.roleData2 = CustomPlayer._getRole(player.args.role2) or {}

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createBottomContent = CustomPlayer.createBottomContent
	player.createWidgetInjector = CustomPlayer.createWidgetInjector
	player.defineCustomPageVariables = CustomPlayer.defineCustomPageVariables
	player.getPersonType = CustomPlayer.getPersonType

	_args = player.args

	local builtInfobox = player:createInfobox()

	local autoPlayerIntro = ''
	if Logic.readBool((_args.autoPI or ''):lower()) then
		autoPlayerIntro = PlayerIntroduction.run{
			team = _args.team,
			name = Logic.emptyOr(_args.romanized_name, _args.name),
			romanizedname = _args.romanized_name,
			status = _args.status,
			type = player.roleData.personType,
			role = player.roleData.variable,
			role2 = player.roleData2.variable,
			id = _args.id,
			idIPA = _args.idIPA,
			idAudio = _args.idAudio,
			birthdate = player.age.birthDateIso,
			deathdate = player.age.deathDateIso,
			nationality = _args.country,
			nationality2 = _args.country2,
			nationality3 = _args.country3,
			subtext = _args.subtext,
			freetext = _args.freetext,
		}
	elseif String.isNotEmpty(_args.freetext) then
		autoPlayerIntro = _args.freetext
	end

	return mw.html.create()
		:node(builtInfobox)
		:node(autoPlayerIntro)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{name = 'Status', content = {CustomPlayer._getStatus()}},
			Cell{name = 'Years Active (Player)', content = {_args.years_active}},
			Cell{name = 'Years Active (Org)', content = {_args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {_args.years_active_coach}},
		}
	elseif id == 'role' then
		return {
			Cell{name = 'Role', content = {
				CustomPlayer._createRole(_args.role),
				CustomPlayer._createRole(_args.role2)
			}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			content = {_args.retired}
		})
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	if String.isEmpty(_args.mmr) then
		return {}
	end

	local mmrDisplay = '[[Leaderboards|' .. _args.mmr .. ']]'
	if String.isNotEmpty(_args.mmrdate) then
		mmrDisplay = mmrDisplay .. '&nbsp;<small><i>(last update: ' .. _args.mmrdate .. '</i></small>'
	end

	return {Cell{name = 'Solo MMR', content = {mmrDisplay}}}
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.role = self.roleData.variable
	lpdbData.extradata.role2 = self.roleData2.variable

	lpdbData.type = Logic.emptyOr(self.roleData.variable, 'player')

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {_args.country})

	return lpdbData
end

function CustomPlayer:createBottomContent(infobox)
	local components = {}
	if Player:shouldStoreData(_args) and String.isNotEmpty(_args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(),_args.team)

		table.insert(components,
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing matches of', {team = teamPage}))
		table.insert(components,
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage}))
	end

	return table.concat(components)
end

function CustomPlayer._getStatus()
	if String.isNotEmpty(_args.status) then
		return Page.makeInternalLink({onlyIfExists = true}, _args.status) or _args.status
	end
end

function CustomPlayer._createRole(role)
	local roleData = CustomPlayer._getRole(role)
	if not roleData then
		return
	end
	if Player:shouldStoreData(_args) then
		local categoryCoreText = 'Category:' .. roleData.category

		return '[[' .. categoryCoreText .. ']]' .. '[[:' .. categoryCoreText .. '|' ..
			roleData.variable .. ']]'
	else
		return roleData.variable
	end
end

function CustomPlayer:defineCustomPageVariables(args)
	if self.roleData then
		Variables.varDefine('role', self.roleData.variable)
		Variables.varDefine('type', self.roleData.personType)
	end

	-- If the role is missing, assume it is a player
	if self.roleData and self.roleData.isplayer == false then
		Variables.varDefine('isplayer', 'false')
	else
		Variables.varDefine('isplayer', 'true')
	end

	if self.roleData2 then
		Variables.varDefine('role2', self.roleData2.variable)
		Variables.varDefine('type2', self.roleData2.personType)
	end
end

function CustomPlayer:getPersonType(args)
	local roleData = CustomPlayer._getRole(args.role)
	if roleData then
		local personType = mw.getContentLanguage():ucfirst(roleData.personType or 'player')
		local categoryValue = roleData.category == _ROLES.coach.category and roleData.category or personType

		return {store = personType, category = categoryValue}
	end

	return {store = 'Player', category = 'Player'}
end

function CustomPlayer._getRole(roleInput)
	if String.isEmpty(roleInput) then
		return
	end

	return _ROLES[roleInput:lower()]
end

return CustomPlayer
