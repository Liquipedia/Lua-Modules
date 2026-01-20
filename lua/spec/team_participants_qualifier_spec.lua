--- Triple Comment to Enable our LLS Plugin
describe('Team Participants Qualification Placement', function()
	local TeamParticipantsWikiParser

	before_each(function()
		TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')
	end)

	insulate('placement field parsing', function()
		local TeamTemplateMock
		local LpdbQuery

		before_each(function()
			TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
			TeamTemplateMock.setUp()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
		end)

		after_each(function()
			LpdbQuery:revert()
			TeamTemplateMock.tearDown()
		end)

		it('parses valid positive integer placement as string', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier A',
					placement = '5'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.are_equal('5', result.qualification.placement)
		end)

		it('parses valid positive range of placements', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier B',
					placement = '3-4'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.are_equal('3-4', result.qualification.placement)
		end)

		it('parses valid positive integer placement as number', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier B',
					placement = 3
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.are_equal('3', result.qualification.placement)
		end)

		it('rejects decimal placement', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier G',
					placement = '2.9'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
		end)

		it('handles large positive placement numbers', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier H',
					placement = '999'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.are_equal('999', result.qualification.placement)
		end)

		it('ignores zero placement', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier C',
					placement = '0'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
		end)

		it('ignores negative placement', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier D',
					placement = '-1'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
		end)

		it('ignores invalid non-numeric placement', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier E',
					placement = 'abc'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
		end)

		it('handles missing placement gracefully', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier F'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
		end)

		it('preserves other qualification fields when placement is present', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Custom Text',
					placement = '7'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.are_equal('7', result.qualification.placement)
			assert.are_equal('qual', result.qualification.method)
			assert.are_equal('Custom Text', result.qualification.text)
		end)
	end)

	insulate('placement validation warnings', function()
		local TeamTemplateMock
		local LpdbQuery

		before_each(function()
			TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
			TeamTemplateMock.setUp()
			LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
		end)

		after_each(function()
			LpdbQuery:revert()
			TeamTemplateMock.tearDown()
		end)

		it('generates warning for zero placement', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier C',
					placement = '0'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
			assert.are_equal(1, #result.warnings)
			assert.matches('Invalid placement: 0', result.warnings[1])
		end)

		it('generates warning for negative placement', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier D',
					placement = '-5'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
			assert.are_equal(1, #result.warnings)
			assert.matches('Invalid placement: %-5$', result.warnings[1])
		end)

		it('generates warning for non-numeric placement', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier E',
					placement = 'abc'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
			assert.are_equal(1, #result.warnings)
			assert.matches('Invalid placement: abc$', result.warnings[1])
		end)

		it('generates warning for placement with special characters', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier X',
					placement = '#1'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
			assert.are_equal(1, #result.warnings)
			assert.matches('Invalid placement: #1$', result.warnings[1])
		end)

		it('generates warning for ordinal placement', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier Y',
					placement = '1st'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
			assert.are_equal(1, #result.warnings)
			assert.matches('Invalid placement: 1st$', result.warnings[1])
		end)

		it('generates warning for decimal placement', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier G',
					placement = '2.9'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
			assert.are_equal(1, #result.warnings)
			assert.matches('Invalid placement: 2%.9$', result.warnings[1])
		end)

		it('does not generate warning for valid positive placement', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier Valid',
					placement = '5'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.are_equal('5', result.qualification.placement)
			assert.are_equal(0, #result.warnings)
		end)

		it('does not generate warning when no placement is provided', function()
			local input = {
				'team liquid',
				qualification = {
					method = 'qual',
					text = 'Qualifier No Placement'
				}
			}
			local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())
			assert.is_nil(result.qualification.placement)
			assert.are_equal(0, #result.warnings)
		end)
	end)
end)
