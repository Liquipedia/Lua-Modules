---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local MatchTicker = Lua.import('Module:MatchTicker/Custom')
local Page = Lua.import('Module:Page')
local PlayerIntroduction = Lua.import('Module:PlayerIntroduction/Custom')
local String = Lua.import('Module:StringUtils')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

local Widgets = Lua.import('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell

---@class LeagueoflegendsInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)

---@class LeagueoflegendsInfoboxPlayerWidgetInjector: WidgetInjector
---@field caller LeagueoflegendsInfoboxPlayer
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	local args = player.args
	player:setWidgetInjector(CustomInjector(player))

	local builtInfobox = player:createInfobox()

	local autoPlayerIntro = ''
	if Logic.readBool((args.autoPI or ''):lower()) then
		autoPlayerIntro = PlayerIntroduction.run{
			player = player.pagename,
			team = args.team,
			name = args.romanized_name or args.name,
			firstname = args.first_name,
			lastname = args.last_name,
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

	return HtmlWidgets.Fragment{children = {
		builtInfobox,
		autoPlayerIntro,
	}}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'status' then
		local status = args.status
		if String.isNotEmpty(status) then
			status = mw.getContentLanguage():ucfirst(status)
		end

		return {
			Cell{name = 'Status', children = {Page.makeInternalLink({onlyIfExists = true},
						status) or status}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			children = {args.retired}
		})
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args)
	lpdbData.extradata.signatureChampion1 = args.champion1 or args.champion
	lpdbData.extradata.signatureChampion2 = args.champion2
	lpdbData.extradata.signatureChampion3 = args.champion3
	lpdbData.extradata.signatureChampion4 = args.champion4
	lpdbData.extradata.signatureChampion5 = args.champion5

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = TeamTemplate.getPageName(args.team2)
	end

	return lpdbData
end

---@return Widget?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = TeamTemplate.getPageName(self.args.team)
		---@cast teamPage -nil
		return HtmlWidgets.Fragment{
			children = {
				MatchTicker.participant{team = teamPage},
				UpcomingTournaments.team{name = teamPage},
			}
		}
	end
end

return CustomPlayer
