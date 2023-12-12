--- Triple Comment to Enable our LLS Plugin
describe('Game', function()
	local Game = require('Module:Game')
	local Info = require('Module:Info')

	local COMMONS_IDENTIFIER = 'commons'
	local COMMONS_DATA = Info.games.commons
	local COMMONS_ICON = '[[File:Liquipedia logo.png|Commons|link=lpcommons:Main Page|class=|25x25px]]'
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
				Game.icon({noSpan = true}))
			assert.are_equal('<span class="span-class">' .. COMMONS_ICON .. '</span>',
				tostring(Game.icon({spanClass = 'span-class'})))
			assert.are_equal('<span class="icon-16px">' .. COMMONS_ICON .. '</span>',
				tostring(Game.icon()))
		end)
	end)

	describe('text', function()
		it('verify',
			function()
				assert.are_equal('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.name .. ']]', Game.text())
				assert.are_equal('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.name .. ']]', Game.text({}))
				assert.are_equal('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.name .. ']]', Game.text({game = ''}))
				assert.are_equal(COMMONS_DATA.name, Game.text({noLink = true}))
				assert.are_equal('[[' .. 'ABC123' .. '|' .. COMMONS_DATA.name .. ']]', Game.text({link = 'ABC123'}))
				assert.are_equal('[[' .. COMMONS_DATA.link .. '|' .. COMMONS_DATA.abbreviation .. ']]',
					Game.text({useAbbreviation = true}))
				assert.are_equal(COMMONS_DATA.abbreviation, Game.text({noLink = true, useAbbreviation = true}))
				assert.are_equal('[[' .. 'ABC123' .. '|' .. COMMONS_DATA.abbreviation .. ']]',
					Game.text({useAbbreviation = true, link = 'ABC123'}))
				assert.are_equal('<abbr title="The specified game input is not recognized">Unknown Game</abbr>',
					Game.text({useDefault = false}))
				assert.are_equal('<abbr title="The specified game input is not recognized">Unkwn.</abbr>',
					Game.text({useDefault = false, useAbbreviation = true}))
			end)
	end)

	describe('list games', function()
		it('verify', function()
			assert.are_equal(COMMONS_IDENTIFIER, Game.listGames()[1])
			assert.are_equal(COMMONS_IDENTIFIER, Game.listGames({ordered = true})[1])
			assert.are_equal(COMMONS_IDENTIFIER, Game.listGames({ordered = false})[1])
		end)
	end)

	describe('default team logo', function()
		it('verify', function()
			assert.are_equal(true, Game.isDefaultTeamLogo{logo = 'Liquipedia logo.png'})
			assert.are_equal(false, Game.isDefaultTeamLogo{logo = 'Liquipedia logo.jpg'})
			assert.are_equal(false, Game.isDefaultTeamLogo{logo = 'bviarBRVNUI.jpg'})

			assert.error(function()
				Game.isDefaultTeamLogo{logo = 'Liquipedia logo.png', game = GAME_TO_THROW}
			end, 'Invalid game input "' .. GAME_TO_THROW .. '"')
		end)
	end)
end)
