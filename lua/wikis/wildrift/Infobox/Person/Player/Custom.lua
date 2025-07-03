---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local ChampionNames = Lua.import('Module:ChampionNames', {loadData = true})
local CharacterIcon = Lua.import('Module:CharacterIcon')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local PlayerIntroduction = Lua.import('Module:PlayerIntroduction/Custom')
local String = Lua.import('Module:StringUtils')
local Team = Lua.import('Module:Team')
local TeamHistoryAuto = Lua.import('Module:TeamHistoryAuto')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local SIZE_CHAMPION = '25x25px'

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	local args = player.args
	player:setWidgetInjector(CustomInjector(player))

	if String.isEmpty(args.history) then
		args.history = TeamHistoryAuto.results{addlpdbdata = true}
	end
	args.autoTeam = true

	local builtInfobox = player:createInfobox()

	local autoPlayerIntro = ''
	if Logic.readBool((args.autoPI or ''):lower()) then
		autoPlayerIntro = PlayerIntroduction.run{
			player = player.pagename,
			team = args.team,
			name = args.romanized_name or args.name,
			first_name = args.first_name,
			last_name = args.last_name,
			status = args.status,
			type = player:getPersonType(args).store,
			roles = player._getKeysOfRoles(player.roles),
			id = args.id,
			idIPA = args.idIPA,
			idAudio = args.idAudio,
			birthdate = player.age.birthDateIso,
			deathdate = player.age.deathDateIso,
			nationality = args.country,
			nationality2 = args.country2,
			nationality3 = args.country3,
			subtext = args.subtext,
			freetext = args.freetext,
			convert_role = true,
			show_role = true,
		}
	end

	return mw.html.create()
		:node(builtInfobox)
		:node(autoPlayerIntro)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		-- Signature Champion
		local championIcons = Array.map(caller:getAllArgsForBase(args, 'champion'), function(champion)
			return CharacterIcon.Icon{character = ChampionNames[champion:lower()], size = SIZE_CHAMPION}
		end)
		return {Cell{
			name = #championIcons > 1 and 'Signature Champions' or 'Signature Champions',
			content = {table.concat(championIcons, '&nbsp;')},
		}}
	elseif id == 'status' then
		local status = args.status and mw.getContentLanguage():ucfirst(args.status) or nil

		return {
			Cell{name = 'Status', content = {Page.makeInternalLink({onlyIfExists = true}, status) or status}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	for index, champion in ipairs(self:getAllArgsForBase(args, 'champion')) do
		lpdbData.extradata['signatureChampion' .. index] = ChampionNames[champion:lower()]
	end
	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(args.team2).page
	end

	return lpdbData
end

---@return string?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(), self.args.team)
		return
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing matches of', {team = teamPage}) ..
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage})
	end
end

return CustomPlayer
