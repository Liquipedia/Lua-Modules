---
-- @Liquipedia
-- page=Module:I18n/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	en = {
		-- Tournament Filter
		['tournament-ticker-no-tournaments'] = 'No tournaments found for your selected filters!',

		-- Filter Buttons
		['filterbuttons-all'] = 'All',
		['filterbuttons-featured'] = 'Curated',

		-- Dates
		['date-unknown'] = 'TBA',
		['date-range-different-months'] = '${startMonth} ${startDate} - ${endMonth} ${endDate}',
		['date-range-same-month'] = '${startMonth} ${startDate} - ${endDate}',
		['date-range-same-day'] = '${startMonth} ${startDate}',
		['date-range-different-months-unknown-end'] = '${startMonth} ${startDate} - TBA',
		['date-range-different-months-unknown-end-day'] = '${startMonth} ${startDate} - ${endMonth} TBA',
		['date-range-different-months-unknown-days'] = '${startMonth} - ${endMonth}',
		['date-range-different-months-unknown-days-and-end-month'] = '${startMonth} - TBA',
		['date-range-same-month-unknown-days'] = '${startMonth}',

		-- Bracket Headers
		['brkts-header-r1'] = 'Grand Final,Final,GF',
		['brkts-header-r2'] = 'Semifinals,Semis,SF',
		['brkts-header-r3'] = 'Quarterfinals,Quarters,QF',
		['brkts-header-r4'] = 'Round ${round},R${round}',
		['brkts-header-rx'] = 'Round ${round},R${round}',

		['brkts-header-u1'] = 'Grand Final,Final,GF',
		['brkts-header-u2'] = 'Upper Bracket Final,UB Final,UBF',
		['brkts-header-u3'] = 'Upper Bracket Semifinals,UB Semifinals,UBSF',
		['brkts-header-u4'] = 'Upper Bracket Quarterfinals,UB Quarterfinals,UBQF',
		['brkts-header-ux'] = 'Upper Bracket Round ${round},UB Round ${round},UBR${round}',

		['brkts-header-m1'] = 'Mid Bracket Final,MB Final,MBF',
		['brkts-header-m2'] = 'Mid Bracket Semifinal,MB Semifinal,MBSF',
		['brkts-header-m3'] = 'Mid Bracket Quarterfinal,MB Quarterfinal,MBQF',
		['brkts-header-m4'] = 'Mid Bracket Round ${round},MB Round ${round},MBR${round}',
		['brkts-header-mx'] = 'Mid Bracket Round ${round},MB Round ${round},MBR${round}',

		['brkts-header-l2'] = 'Lower Bracket Final,LB Final,LBF',
		['brkts-header-l3'] = 'Lower Bracket Semifinal,LB Semifinal,LBSF',
		['brkts-header-l4'] = 'Lower Bracket Quarterfinals,LB Quarterfinals,LBQF',
		['brkts-header-lx'] = 'Lower Bracket Round ${round},LB Round ${round},LBR${round}',

		['brkts-header-q'] = 'Qualified,Qual.,Q',
		['brkts-header-tp'] = 'Third Place Match,3rd Place,3rd',

		-- MatchSummary Map Veto
		['matchsummary-mapveto-start'] = 'Start Map Veto',
	}
}
