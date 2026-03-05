---
-- @Liquipedia
-- page=Module:Player/Display/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Faction = Lua.import('Module:Faction')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local PlayerDisplay = Lua.import('Module:Player/Display')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

---Display components for players used in the starcraft and starcraft2 wikis.
---@class StarcraftPlayerDisplay: PlayerDisplay
local StarcraftPlayerDisplay = Table.copy(PlayerDisplay)

---Called from Template:Player and Template:Player2
---Only for non git usage!
---@param frame Frame
---@return string
function StarcraftPlayerDisplay.TemplatePlayer(frame)
	local args = Lua.import('Module:Arguments').getArgs(frame)

	local pageName
	local displayName
	if not args.noclean then
		pageName, displayName = PlayerExt.extractFromLink(args[1] or '')
		local showLink = Logic.readBoolOrNil(args.link)
		if showLink == true then
			pageName = displayName
		elseif showLink == false then
			pageName = nil
		else
			pageName = args.link or pageName or displayName
		end
	else
		pageName = args.link
		displayName = args[1] or ''
	end

	local player = {
		displayName = displayName,
		flag = String.nilIfEmpty(args.flag),
		pageName = pageName,
		faction = String.nilIfEmpty(args.race) or String.nilIfEmpty(args.faction) or Faction.defaultFaction,
	}
	PlayerExt.populatePageName(player)

	if not args.novar then
		PlayerExt.saveToPageVars(player, {overwritePageVars = true})
	end

	local hiddenSortNode = args.hs
		and StarcraftPlayerDisplay.HiddenSort(player.displayName, player.flag, player.faction, args.hs)
		or ''
	local playerNode = StarcraftPlayerDisplay.InlinePlayer({
		dq = Logic.readBoolOrNil(args.dq),
		flip = Logic.readBoolOrNil(args.flip),
		player = player,
		showFaction = Logic.nilOr(Logic.readBoolOrNil(args.showRace), Logic.readBoolOrNil(args.showFaction), true),
	})
	return tostring(hiddenSortNode) .. tostring(playerNode)
end

---Called from Template:InlinePlayer
---Only for non git usage!
---@param frame Frame
---@return Html
function StarcraftPlayerDisplay.TemplateInlinePlayer(frame)
	local args = Lua.import('Module:Arguments').getArgs(frame)

	local player = {
		displayName = args[1],
		flag = args.flag,
		pageName = args.link,
		faction = Faction.read(args.race or args.faction),
	}

	PlayerExt.syncPlayer(player, {
		date = args.date,
		savePageVar = not Logic.readBool(args.novar),
		overwritePageVars = true,
	})

	return StarcraftPlayerDisplay.InlinePlayer{
		date = args.date,
		dq = Logic.readBoolOrNil(args.dq),
		flip = Logic.readBoolOrNil(args.flip),
		player = player,
		savePageVar = not Logic.readBool(args.novar),
		showFlag = Logic.readBoolOrNil(args.showFlag),
		showLink = Logic.readBoolOrNil(args.showLink),
		showFaction = Logic.nilOr(Logic.readBoolOrNil(args.showRace), Logic.readBoolOrNil(args.showFaction)),
	}
end

---@param name string?
---@param flag string?
---@param faction string?
---@param field string?
---@return Html
function StarcraftPlayerDisplay.HiddenSort(name, flag, faction, field)
	local text
	if field == 'race' or field == 'faction' then
		text = faction
	elseif field == 'name' then
		text = name
	elseif field == 'flag' then
		text = flag
	else
		text = field
	end

	return mw.html.create('span')
		:css('display', 'none')
		:wikitext(text)
end

return StarcraftPlayerDisplay
