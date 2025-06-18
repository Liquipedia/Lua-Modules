---
-- @Liquipedia
-- page=Module:PortalPlayers/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Links = Lua.import('Module:Links')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Team = Lua.import('Module:Team')

local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibrary.OpponentDisplay

local Characters = Lua.import('Module:Characters')

local NON_PLAYER_HEADER = Abbreviation.make{text = 'Staff', title = 'Coaches, Managers, Analysts and more'}
	.. ' & ' .. Abbreviation.make{text = 'Talents', title = 'Commentators, Observers, Hosts and more'}
local BACKGROUND_CLASSES = {
	inactive = 'sapphire-bg',
	retired = 'bg-neutral',
	banned = 'cinnabar-bg',
	['passed away'] = 'gigas-bg',
}

local PortalPlayers = Lua.import('Module:PortalPlayers')

local CustomPortalPlayers = {}

---Entry Point. Builds the player portal
---@param frame Frame
---@return Html
function CustomPortalPlayers.run(frame)
	local args = Arguments.getArgs(frame)

	local portalPlayers = PortalPlayers(args)

	portalPlayers.header = CustomPortalPlayers.header
	portalPlayers.row = CustomPortalPlayers.row

	return portalPlayers:create()
end

---Builds the header for the table
---@param args {flag: string, isPlayer: boolean?}
---@return Html
function CustomPortalPlayers:header(args)
	local teamText = args.isPlayer and ' Team' or ' Team and Role'

	local header = mw.html.create('tr')
		:tag('th')
			:attr('colspan', 5)
			:css('padding-left', '1em')
			:wikitext(args.flag .. ' ' .. (args.isPlayer and self.playerType or NON_PLAYER_HEADER))
			:done()

	local subHeader = mw.html.create('tr')
		:tag('th'):css('width', '175px'):wikitext(' ID'):done()
		:tag('th'):css('width', '175px'):wikitext(' Real Name'):done()
		:tag('th'):css('width', '52px'):wikitext(' Main'):done()
		:tag('th'):css('width', '250px'):wikitext(teamText):done()
		:tag('th'):css('width', '120px'):wikitext(' Links'):done()

	return mw.html.create()
		:node(header)
		:node(subHeader)
end

---Builds a table row
---@param player table
---@param isPlayer boolean
---@return Html
function CustomPortalPlayers:row(player, isPlayer)
	local row = mw.html.create('tr')
		:addClass(BACKGROUND_CLASSES[(player.status or ''):lower()])

	row:tag('td'):wikitext(' '):node(OpponentDisplay.BlockOpponent{opponent = PortalPlayers.toOpponent(player)})
	row:tag('td')
		:wikitext(' ' .. player.name)
		:wikitext(self.showLocalizedName and (' (' .. player.localizedname .. ')') or nil)

	row:tag('td'):node(CustomPortalPlayers._getMainCharIcons(player))

	local role = not isPlayer and mw.language.getContentLanguage():ucfirst((player.extradata or {}).role or '') or ''
	local teamText = mw.ext.TeamTemplate.teamexists(player.team) and Team.team(nil, player.team) or ''
	if String.isNotEmpty(role) and String.isEmpty(teamText) then
		teamText = role
	elseif String.isNotEmpty(role) then
		teamText = teamText .. ' (' .. role .. ')'
	end
	row:tag('td'):wikitext(' ' .. teamText)

	local links = Array.extractValues(Table.map(player.links or {}, function(key, link)
		return key, ' [' .. link .. ' ' .. Links.makeIcon(Links.removeAppendedNumber(key), 25) .. ']'
	end) or {}, Table.iter.spairs)

	row:tag('td')
		:addClass('plainlinks')
		:css('line-height', '25px')
		:css('padding', '1px 2px 1px 2px')
		:css('max-width', '112px')
		:wikitext(table.concat(links))

	return row
end

---Builds the main cahracter display
---@param player table
---@return Html?
function CustomPortalPlayers._getMainCharIcons(player)
	if String.isEmpty(player.extradata.maingame) then
		return
	end

	local activeGame = player.extradata.maingame

	if String.isEmpty(player.extradata['main' .. activeGame]) then
		mw.log('Missing "main' .. activeGame .. '" in extradata on player page ' .. player.pagename)
		return
	end

	local CharacterIcons = Lua.import('Module:CharacterIcons/' .. activeGame, {loadData = true})

	local display = mw.html.create()
	for _, character in ipairs(mw.text.split(player.extradata['main' .. activeGame], ',', true)) do
		display
			:wikitext(' ')
			:wikitext(Characters._GetIconAndName(CharacterIcons, character, false) or '')
	end

	return display
end

return CustomPortalPlayers
