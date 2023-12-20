--- Triple Comment to Enable our LLS Plugin
describe('Opponent Display', function()
	local OpponentDisplay = require('Module:OpponentDisplay')

	describe('Inline Opponent', function()
		describe('Solo', function()
			local opponent = {type = 'solo', players = {{displayName = 'test', pageName = 'link', flag = 'de'}}}
			it('default display', function()
				assert.are_equal(
					'<span><span class="inline-player" style="white-space:pre">'
					.. '<span class="flag">[[File:de_hd.png|36x24px|Germany|link=]]</span>'
					.. '&nbsp;[[link|test]]</span></span>',
					tostring(OpponentDisplay.InlineOpponent{opponent = opponent}))
			end)
			it('Disabling flags', function()
				assert.are_equal(
					'<span><span class="inline-player" style="white-space:pre">[[link|test]]</span></span>',
					tostring(OpponentDisplay.InlineOpponent{showFlag = false, opponent = opponent}))
			end)
			it('Showing flags', function()
				assert.are_equal(
					'<span><span class="inline-player" style="white-space:pre">'
					.. '<span class="flag">[[File:de_hd.png|36x24px|Germany|link=]]</span>'
					.. '&nbsp;[[link|test]]</span></span>',
					tostring(OpponentDisplay.InlineOpponent{showFlag = true, opponent = opponent}))
			end)
			it('Hiding links', function()
				assert.are_equal(
					'<span><span class="inline-player" style="white-space:pre">'
					.. '<span class="flag">[[File:de_hd.png|36x24px|Germany|link=]]</span>'
					.. '&nbsp;test</span></span>',
					tostring(OpponentDisplay.InlineOpponent{showLink = false, opponent = opponent}))
			end)
			it('Showing links', function()
				assert.are_equal(
					'<span><span class="inline-player" style="white-space:pre">'
					.. '<span class="flag">[[File:de_hd.png|36x24px|Germany|link=]]</span>'
					.. '&nbsp;[[link|test]]</span></span>',
					tostring(OpponentDisplay.InlineOpponent{showLink = true, opponent = opponent}))
			end)
			it('Strikethrough/DQ', function()
				assert.are_equal(
					'<span><span class="inline-player" style="white-space:pre">'
					.. '<span class="flag">[[File:de_hd.png|36x24px|Germany|link=]]</span>'
					.. '&nbsp;<s>[[link|test]]</s></span></span>',
					tostring(OpponentDisplay.InlineOpponent{dq = true, opponent = opponent}))
			end)

			it('missing links', function()
				opponent.players[1].pageName = nil
				assert.are_equal(
					'<span><span class="inline-player" style="white-space:pre">'
					.. '<span class="flag">[[File:de_hd.png|36x24px|Germany|link=]]</span>'
					.. '&nbsp;test</span></span>',
					tostring(OpponentDisplay.InlineOpponent{showLink = true, opponent = opponent}))
			end)
		end)
	end)
end)
