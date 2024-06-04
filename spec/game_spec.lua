--- Triple Comment to Enable our LLS Plugin
describe('Game', function()
	insulate('Commons', function ()
		local Game = require('Module:Game')
		local Info = require('Module:Info')

		local COMMONS_IDENTIFIER = 'commons'
		local COMMONS_DATA = Info.games.commons
		local COMMONS_ICON = '[[File:Liquipedia logo.png|Commons|link=lpcommons:Main Page|class=|32x32px]]'
		local GAME_TO_THROW = 'please throw'

		describe('to identifier', function()
			it('verify', function()
				assert.are_equal(COMMONS_IDENTIFIER, Game.toIdentifier())
				assert.is_nil(Game.toIdentifier{useDefault = false})
				assert.is_nil(Game.toIdentifier{game = 'lp'})
				assert.are_equal(COMMONS_IDENTIFIER, Game.toIdentifier{game = 'comMoNs'})
			end)
		end)

		describe('data retrieve', function()
			it('verify', function()
				assert.are_same(COMMONS_DATA, Game.raw())
				assert.are_equal(COMMONS_DATA.abbreviation, Game.abbreviation())
				assert.are_equal(COMMONS_DATA.name, Game.name())
				assert.are_equal(COMMONS_DATA.link, Game.link())
				assert.are_same(COMMONS_DATA.defaultTeamLogo, Game.defaultTeamLogoData())
			end)
		end)

		describe('icon', function()
			it('verify', function()
				assert.are_equal(COMMONS_ICON,
					Game.icon{noSpan = true})
				assert.are_equal('<span class="span-class">' .. COMMONS_ICON .. '</span>',
					tostring(Game.icon{spanClass = 'span-class'}))
				assert.are_equal('<span class="icon-16px">' .. COMMONS_ICON .. '</span>',
					tostring(Game.icon()))
				assert.are_equal('[[File:Liquipedia logo.png|Commons|link=lpcommons:Main Page|class=|24x24px]]',
					tostring(Game.icon{size = '24x24px'}))
			end)
		end)

		describe('text', function()
			it('verify',
				function()
					assert.are_equal('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.name .. ']]', Game.text())
					assert.are_equal('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.name .. ']]', Game.text{})
					assert.are_equal('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.name .. ']]', Game.text{game = ''})
					assert.are_equal(COMMONS_DATA.name, Game.text{noLink = true})
					assert.are_equal('[[' .. 'ABC123' .. '|' .. COMMONS_DATA.name .. ']]', Game.text{link = 'ABC123'})
					assert.are_equal('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.abbreviation .. ']]',
						Game.text{useAbbreviation = true})
					assert.are_equal(COMMONS_DATA.abbreviation, Game.text{noLink = true, useAbbreviation = true})
					assert.are_equal('[[' .. 'ABC123' .. '|' .. COMMONS_DATA.abbreviation .. ']]',
						Game.text{useAbbreviation = true, link = 'ABC123'})
					assert.are_equal('<abbr title="The specified game input is not recognized">Unknown Game</abbr>',
						Game.text{useDefault = false})
					assert.are_equal('<abbr title="The specified game input is not recognized">Unkwn.</abbr>',
						Game.text{useDefault = false, useAbbreviation = true})
				end)
		end)

		describe('list games', function()
			it('verify', function()
				assert.are_equal(COMMONS_IDENTIFIER, Game.listGames()[1])
				assert.are_equal(COMMONS_IDENTIFIER, Game.listGames{ordered = true}[1])
				assert.are_equal(COMMONS_IDENTIFIER, Game.listGames{ordered = false}[1])
			end)
		end)

		describe('default team logo', function()
			it('verify', function()
				assert.is_true(Game.isDefaultTeamLogo{logo = 'Liquipedia logo.png'})
				assert.is_false(Game.isDefaultTeamLogo{logo = 'Liquipedia logo.jpg'})
				assert.is_false(Game.isDefaultTeamLogo{logo = 'bviarBRVNUI.jpg'})

				assert.error(function()
					Game.isDefaultTeamLogo{logo = 'Liquipedia logo.png', game = GAME_TO_THROW}
				end, 'Invalid game input "' .. GAME_TO_THROW .. '"')
			end)
		end)
	end)

	insulate('counterstrike', function ()
		local Game
		setup(function()
			SetActiveWiki('counterstrike')
			Game = require('Module:Game')
		end)
		teardown(function()
			SetActiveWiki()
		end)
		describe('list games hiddens', function ()
			it('default', function ()
				assert.are_same({'cs1', 'css', 'cscz', 'cs2', 'csgo', 'cs16', 'cs', 'cso'}, Game.listGames())
			end)
			it('ordered', function ()
				assert.are_same({'cs1', 'cs', 'cs16', 'cscz', 'css', 'cso', 'csgo', 'cs2'}, Game.listGames{ordered = true})
			end)
		end)
	end)
end)
