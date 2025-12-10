---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local CharacterNames = Lua.import('Module:CharacterNames', {loadData = true})
local GameAppearances = Lua.import('Module:GetGameAppearances')
local String = Lua.import('Module:StringUtils')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Template = Lua.import('Module:Template')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Injector = Lua.import('Module:Widget/Injector')
local MatchTicker = Lua.import('Module:MatchTicker/Custom')
local Player = Lua.import('Module:Infobox/Person')
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center

local SIZE_HERO = '25x25px'
local MAX_NUMBER_OF_SIGNATURE_HEROES = 3

---@class OverwatchInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)

---@class OverwatchInfoboxPlayerWidgetInjector: WidgetInjector
---@field caller OverwatchInfoboxPlayer
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local heroes = Array.sub(caller:getAllArgsForBase(args, 'hero'), 1, MAX_NUMBER_OF_SIGNATURE_HEROES)
		local heroIcons = Array.map(heroes, function(hero)
			return CharacterIcon.Icon{character = CharacterNames[hero:lower()], size = SIZE_HERO}
		end)

		Array.appendWith(widgets,
			Cell{
				name = #heroIcons > 1 and 'Signature Heroes' or 'Signature Hero',
				children = {table.concat(heroIcons, '&nbsp;')},
			},
			Cell{
				name = 'Game Appearances',
				children = GameAppearances.player({player = caller.pagename})
			}
		)
	elseif id == 'history' then
		if args.nationalteams then
			table.insert(widgets, 1, Center{children = {args.nationalteams}})
		end
		table.insert(widgets, Cell{name = 'Retired', children = {args.retired}})
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args)
	-- store signature heroes with standardized name
	for heroIndex, hero in ipairs(self:getAllArgsForBase(args, 'hero')) do
		lpdbData.extradata['signatureHero' .. heroIndex] = CharacterNames[hero:lower()]
		if heroIndex == MAX_NUMBER_OF_SIGNATURE_HEROES then
			break
		end
	end

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(args.team2).page
	end

	return lpdbData
end

---@return Widget?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = TeamTemplate.getPageName(self.args.team)
		local team2Page = String.isNotEmpty(self.args.team2) and TeamTemplate.getPageName(self.args.team2) or nil

		return HtmlWidgets.Fragment{children = WidgetUtil.collect(
			MatchTicker.player{recentLimit = 3},
			UpcomingTournaments.team{name = {teamPage, team2Page}}
		)}
	end
end

return CustomPlayer
