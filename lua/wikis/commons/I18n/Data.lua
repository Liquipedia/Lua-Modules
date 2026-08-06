---
-- @Liquipedia
-- page=Module:I18n/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	en = {
		-- Match Stream
		['matchstream-watch-live'] = 'Watch now',
		['matchstream-watch-upcoming'] = 'Watch here',

		-- Match Details
		['matchdetails-view-long'] = 'View match details',
		['matchdetails-add-long'] = 'Add details',
		['matchdetails-short'] = 'Details',

		-- Tournament Filter
		['tournament-ticker-no-tournaments'] = 'No tournaments found for your selected filters!',

		-- Filter Buttons
		['filterbuttons-all'] = 'All',
		['filterbuttons-featured'] = 'Curated',

		-- Dates
		['date-unknown'] = 'TBA',
		['date-range-unknown'] = 'TBA',

		-- Dates: Only startYear known
		['date-range-year'] = '${startYear}',
		['date-range-year--unknown'] = '${startYear} – TBA',
		['date-range-year--year'] = '${startYear}–${endYear}',

		-- Dates: Only startYear, startMonth known
		['date-range-year-month'] = '${startMonth}, ${startYear}',
		['date-range-year-month--unknown'] = '${startMonth}, ${startYear} – TBA',
		['date-range-year-month--year-unknown_month'] = '${startMonth}, ${startYear} – TBA, ${endYear}',
		['date-range-year-month--month'] = '${startMonth} – ${endMonth}, ${startYear}',
		['date-range-year-month--year-month'] = '${startMonth}, ${startYear} – ${endMonth}, ${endYear}',

		['date-range-year-month--unknown_month'] = '${startMonth} – TBA, ${startYear}',

		-- Dates: Full startdate known
		['date-range-year-month-day'] = '${startMonth} ${startDate}, ${startYear}',
		['date-range-year-month-day--unknown'] = '${startMonth} ${startDate}, ${startYear} – TBA',
		['date-range-year-month-day--year-unknown_month'] = '${startMonth} ${startDate}, ${startYear} – TBA, ${endYear}',
		['date-range-year-month-day--year-month-unknown_day']
				= '${startMonth} ${startDate}, ${startYear} – ${endMonth} TBA, ${endYear}',
		['date-range-year-month-day--year-month-day']
				= '${startMonth} ${startDate}, ${startYear} – ${endMonth} ${endDate}, ${endYear}',

		['date-range-year-month-day--month-day'] = '${startMonth} ${startDate} – ${endMonth} ${endDate}, ${startYear}',
		['date-range-year-month-day--month-unknown_day'] = '${startMonth} ${startDate} – ${endMonth} TBA, ${startYear}',
		['date-range-year-month-day--day'] = '${startMonth} ${startDate}–${endDate}, ${startYear}',

		-- Dates: ticker variant (hidden years)
		-- startMonth known
		['date-range-month'] = '${startMonth}',
		['date-range-month--unknown'] = '${startMonth} – TBA',
		['date-range-month--unknown_month'] = '${startMonth} – TBA',
		['date-range-month--month'] = '${startMonth} – ${endMonth}',

		-- startMonth and startDay known
		['date-range-month-day'] = '${startMonth} ${startDate}',
		['date-range-month-day--day'] = '${startMonth} ${startDate}–${endDate}',

		['date-range-month-day--unknown'] = '${startMonth} ${startDate} – TBA',
		['date-range-month-day--unknown_month'] = '${startMonth} ${startDate} – TBA',
		['date-range-month-day--month-unknown_day'] = '${startMonth} ${startDate} – ${endMonth} TBA',
		['date-range-month-day--month-day'] = '${startMonth} ${startDate} – ${endMonth} ${endDate}',

		-- HiddenDataBox warnings
		['hiddendatabox-invalid-parent-warning'] = '${parent} is not a Liquipedia Tournament',
		['hiddendatabox-invalid-tier-warning'] = '${tierString} is not a known Liquipedia ${tierMode}',

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
		['brkts-header-m2'] = 'Mid Bracket Semifinals,MB Semifinals,MBSF',
		['brkts-header-m3'] = 'Mid Bracket Quarterfinals,MB Quarterfinals,MBQF',
		['brkts-header-m4'] = 'Mid Bracket Round ${round},MB Round ${round},MBR${round}',
		['brkts-header-mx'] = 'Mid Bracket Round ${round},MB Round ${round},MBR${round}',

		['brkts-header-l2'] = 'Lower Bracket Final,LB Final,LBF',
		['brkts-header-l3'] = 'Lower Bracket Semifinals,LB Semifinals,LBSF',
		['brkts-header-l4'] = 'Lower Bracket Quarterfinals,LB Quarterfinals,LBQF',
		['brkts-header-lx'] = 'Lower Bracket Round ${round},LB Round ${round},LBR${round}',

		['brkts-header-q'] = 'Qualified,Qual.,Q',
		['brkts-header-tp'] = 'Third Place Match,3rd Place,3rd',

		-- MatchPage meta description
		['matchpage-meta-desc'] = 'Find detailed results about the ${ongoingTense}${game} match ' ..
									'between ${opponent1} and ${opponent2} in ${tournamentName}${tense}.',
		['matchpage-meta-desc-no-opponent']
				= 'Find detailed results about the ${ongoingTense}${game} match in ${tournamentName}${tense}.',

		-- Team Participant Card
		['participants-hover-roster-label'] = 'Player roster',
		['participants-notes-label'] = 'Notes (${count})',

		-- MatchSummary Map Veto
		['matchsummary-mapveto-start'] = 'Start Map Veto',

		-- MatchTable
		['matchtable-no-match-results'] = 'This ${mode} has not played any matches yet.',
		['matchtable-no-h2h-match-results'] = 'These ${mode} have not played any matches against each other yet.',

		-- MatchTicker
		['matchticker-upcoming-matches'] = 'Upcoming Matches',

		-- Shop Merch
		['shop-merch-support-text'] = 'Purchases through this link support Liquipedia.',

		-- Dota 2 Main Page
		['dota2-mainpage-title'] = 'The Dota 2 Wiki',
		['dota2-mainpage-metadesc'] = 'Comprehensive Dota 2 wiki with articles covering everything from heroes and items, to strategies, ' ..
		'to tournaments, to competitive players, and teams.',
		['dota2-mainpage-about-heading'] = 'About Liquipedia\'s Dota 2 Wiki',
		['dota2-mainpage-about-body'] = 'We are the largest Dota 2 wiki that anyone can edit, maintained by fans just like you. ' ..
			'This wiki currently covers esports and game content, containing over ${articleCount} articles ' ..
			'managed by ${activeUsersCount} active users.',
		
		['dota2-mainpage-hub-button'] = 'Click here to get to the ',
		['dota2-mainpage-hub-main-title'] = 'Main Page',
		['dota2-mainpage-hub-main-link'] = 'Main Page',
		['dota2-mainpage-hub-esports-title'] = 'Esports Hub',
		['dota2-mainpage-hub-esports-link'] = 'Portal:Esports',
		['dota2-mainpage-hub-game-title'] = 'Game Hub',
		['dota2-mainpage-hub-game-link'] = 'Portal:Game',

		['dota2-mainpage-block-heroes-title'] = 'Heroes',
		['dota2-mainpage-block-updates-title'] = 'Updates',
		['dota2-mainpage-block-usefulArticles-title'] = 'Useful Articles',
		['dota2-mainpage-block-wantToHelp-title'] = 'Want To Help?',
		['dota2-mainpage-block-transfers-title'] = 'Transfers',
		['dota2-mainpage-block-matches-title'] = 'Matches',
		['dota2-mainpage-block-partnerWikis-title'] = 'Partner Wikis',
		['dota2-mainpage-block-tournaments-title'] = 'Tournaments',
		['dota2-mainpage-block-rankings-title'] = 'Liquipedia Rankings',

		['dota2-mainpage-button-heroes-title'] = 'Heroes',
		['dota2-mainpage-button-heroes-link'] = 'Heroes',
		['dota2-mainpage-button-items-title'] = 'Items',
		['dota2-mainpage-button-items-link'] = 'Items',
		['dota2-mainpage-button-mechanics-title'] = 'Mechanics',
		['dota2-mainpage-button-mechanics-link'] = 'Mechanics',
		['dota2-mainpage-button-mechanics-category'] = 'Mechanics',
		['dota2-mainpage-button-cosmetics-title'] = 'Cosmetics',
		['dota2-mainpage-button-cosmetics-link'] = 'Cosmetics',
		['dota2-mainpage-button-updates-title'] = 'Updates',
		['dota2-mainpage-button-updates-link'] = 'Updates',
		['dota2-mainpage-button-tournaments-title'] = 'Tournaments',
		['dota2-mainpage-button-tournaments-link'] = 'Portal:Tournaments',
		['dota2-mainpage-button-teams-title'] = 'Teams',
		['dota2-mainpage-button-teams-link'] = 'Portal:Teams',
		['dota2-mainpage-button-players-title'] = 'Players',
		['dota2-mainpage-button-players-link'] = 'Portal:Players',
		['dota2-mainpage-button-transfers-title'] = 'Transfers',
		['dota2-mainpage-button-transfers-link'] = 'Portal:Transfers',
	},
	ru = {
		-- Match Stream / Трансляции матча
		['matchstream-watch-live'] = 'Смотреть',
		['matchstream-watch-upcoming'] = 'Трансляция',

		-- Match Details / Детали матча
		['matchdetails-view-long'] = 'Детали матча',
		['matchdetails-add-long'] = 'Дополнить',
		['matchdetails-short'] = 'Детали',

		-- Tournament Filter / Фильтр турниров
		['tournament-ticker-no-tournaments'] = 'Не найдено турниров для выбранных фильтров!',

		-- Filter Buttons / Кнопки фильтра
		['filterbuttons-all'] = 'Все',
		['filterbuttons-featured'] = 'Особые',

		-- Dates / Даты
		['date-unknown'] = 'Б/О',
		['date-range-unknown'] = 'Б/О',

		-- Dates: Only startYear known / Даты: Известен год начала
		['date-range-year'] = '${startYear}',
		['date-range-year--unknown'] = '${startYear} – Б/О',
		['date-range-year--year'] = '${startYear}–${endYear}',

		-- Dates: Only startYear, startMonth known / Даты: Известны месяц и год начала
		['date-range-year-month'] = '${startMonth} ${startYear}',
		['date-range-year-month--unknown'] = '${startMonth} ${startYear} – Б/О',
		['date-range-year-month--year-unknown_month'] = '${startMonth} ${startYear} – Б/О, ${endYear}',
		['date-range-year-month--month'] = '${startMonth} – ${endMonth} ${startYear}',
		['date-range-year-month--year-month'] = '${startMonth} ${startYear} – ${endMonth} ${endYear}',

		['date-range-year-month--unknown_month'] = '${startMonth} – Б/О, ${startYear}',

		-- Dates: Full startdate known / Даты: Известна полная дата начала
		['date-range-year-month-day'] = '${startDate} ${startMonth} ${startYear}',
		['date-range-year-month-day--unknown'] = '${startDate} ${startMonth} ${startYear} – Б/О',
		['date-range-year-month-day--year-unknown_month'] = '${startDate} ${startMonth} ${startYear} – Б/О, ${endYear}',
		['date-range-year-month-day--year-month-unknown_day']
				= '${startDate} ${startMonth} ${startYear} – Б/О, ${endMonth} ${endYear}',
		['date-range-year-month-day--year-month-day']
				= '${startDate} ${startMonth} ${startYear} – ${endDate} ${endMonth} ${endYear}',

		['date-range-year-month-day--month-day'] = '${startDate} ${startMonth} – ${endDate} ${endMonth} ${startYear}',
		['date-range-year-month-day--month-unknown_day'] = '${startDate} ${startMonth} –  Б/О, ${endMonth} ${startYear}',
		['date-range-year-month-day--day'] = '${startDate}–${endDate} ${startMonth} ${startYear}',

		-- Dates: ticker variant (hidden years) / Даты: Без отображения года
		-- startMonth known / Известен месяц начала
		['date-range-month'] = '${startMonth}',
		['date-range-month--unknown'] = '${startMonth} – Б/О',
		['date-range-month--unknown_month'] = '${startMonth} – Б/О',
		['date-range-month--month'] = '${startMonth} – ${endMonth}',

		-- startMonth and startDay known / Известны день и месяц начала
		['date-range-month-day'] = '${startDate} ${startMonth}',
		['date-range-month-day--day'] = '${startDate}–${endDate} ${startMonth}',

		['date-range-month-day--unknown'] = '${startDate} ${startMonth} – Б/О',
		['date-range-month-day--unknown_month'] = '${startDate} ${startMonth} – Б/О',
		['date-range-month-day--month-unknown_day'] = '${startDate} ${startMonth} – ${endMonth} Б/О',
		['date-range-month-day--month-day'] = '${startMonth} ${startDate} – ${endMonth} ${endDate}',

		-- HiddenDataBox warnings / Ошибки HiddenDataBox
		['hiddendatabox-invalid-parent-warning'] = '${parent} не является турниром Liquipedia',
		['hiddendatabox-invalid-tier-warning'] = '${tierString} - не турнир Liquipedia ${tierMode}',

		-- Bracket Headers / Заголовки брэкета
		['brkts-header-r1'] = 'Гранд-финал,Финал,ГФ',
		['brkts-header-r2'] = 'Полуфиналы,ПолуФ,ПФ',
		['brkts-header-r3'] = 'Четвертьфиналы,ЧетвертьФ,ЧФ',
		['brkts-header-r4'] = 'Раунд ${round},Р${round}',
		['brkts-header-rx'] = 'Раунд ${round},Р${round}',

		['brkts-header-u1'] = 'Гранд-финал,Финал,ГФ',
		['brkts-header-u2'] = 'Финал верхней сетки,Финал ВС,ФВС',
		['brkts-header-u3'] = 'Полуфинал верхней сетки,Полуфинал ВС,ПФВС',
		['brkts-header-u4'] = 'Четвертьфинал верхней сетки,Четвертьфинал ВС,ЧФВС',
		['brkts-header-ux'] = 'Верхняя сетка Раунд ${round},ВС Раунд ${round},ВСР${round}',

		['brkts-header-m1'] = 'Финал средней сетки,Финал СС,ССФ',
		['brkts-header-m2'] = 'Полуфинал средней сетки,Полуфинал СС,ПФСС',
		['brkts-header-m3'] = 'Четвертьфинал средней сетки,Четвертьфинал СС,ЧФСС',
		['brkts-header-m4'] = 'Средняя сетка Раунд ${round},СС Раунд ${round},ССР${round}',
		['brkts-header-mx'] = 'Средняя сетка Раунд ${round},СС Раунд ${round},ССР${round}',

		['brkts-header-l2'] = 'Финал нижней сетки,Финал НС,НСФ',
		['brkts-header-l3'] = 'Полуфинал нижней сетки,Полуфинал НС,ПФНС',
		['brkts-header-l4'] = 'Четвертьфинал нижней сетки,Четвертьфинал НС,ЧФНС',
		['brkts-header-lx'] = 'Нижняя сетка Раунд ${round},НС Раунд ${round},НСР${round}',

		['brkts-header-q'] = 'Квалифицированы,Квал.,К',
		['brkts-header-tp'] = 'Матч за 3-е место,3-е место,3-е',

		-- MatchPage meta description / Мета-описание страницы MatchPage
		['matchpage-meta-desc'] = 'Ищите детализированные результаты о ${ongoingTense} матче ${game} ' ..
									'между ${opponent1} и ${opponent2} в ${tournamentName}${tense}.',
		['matchpage-meta-desc-no-opponent']
				= 'Ищите детализированные результаты о ${ongoingTense} матче ${game} в ${tournamentName}${tense}.',

		-- Team Participant Card / Карточка команды-участника
		['participants-hover-roster-label'] = 'Состав игроков',
		['participants-notes-label'] = 'Заметки (${count})',

		-- MatchSummary Map Veto
		['matchsummary-mapveto-start'] = 'Карты в вето',

		-- MatchTable
		['matchtable-no-match-results'] = 'Этот участник ещё не играл матчи.',
		['matchtable-no-h2h-match-results'] = 'Эти ${mode} ещё не играли матчи друг против друга.',

		-- MatchTicker
		['matchticker-upcoming-matches'] = 'Будущие матчи',

		-- Shop Merch / Мерч в магазине
		['shop-merch-support-text'] = 'Покупки по этой ссылке поддерживают Liquipedia.',

		-- Dota 2 Main Page / Заглавная Dota 2
		['dota2-mainpage-title'] = 'Dota 2 Вики',
		['dota2-mainpage-metadesc'] = 'Обширная вики по Dota 2, содержащая статьи обо всех аспектах игры: от героев, предметов и стратегий' ..
		'до турниров, профессиональных игроков и команд.',
		['dota2-mainpage-about-heading'] = 'О Dota 2 Wiki от Liquipedia',
		['dota2-mainpage-about-body'] = 'Мы - крупнейшая вики по Dota 2, поддерживаемая такими же фанатами, как и Вы. ' ..
			'Эта вики содержит в себе информацию об игре и её киберспорте, насчитывая ${articleCount} статей, ' ..
			'за которыми следят ${activeUsersCount} активных пользователей.',
		
		['dota2-mainpage-hub-button'] = 'Нажмите, чтобы открыть ',
		['dota2-mainpage-hub-main-title'] = 'Заглавная',
		['dota2-mainpage-hub-main-link'] = 'Заглавная страница',
		['dota2-mainpage-hub-esports-title'] = 'Портал Киберспорт',
		['dota2-mainpage-hub-esports-link'] = 'Портал:Киберспорт',
		['dota2-mainpage-hub-game-title'] = 'Портал Игра',
		['dota2-mainpage-hub-game-link'] = 'Портал:Игра',

		['dota2-mainpage-block-heroes-title'] = 'Герои',
		['dota2-mainpage-block-updates-title'] = 'Обновления',
		['dota2-mainpage-block-usefulArticles-title'] = 'Полезные статьи',
		['dota2-mainpage-block-wantToHelp-title'] = 'Хотите помочь?',
		['dota2-mainpage-block-transfers-title'] = 'Трансферы',
		['dota2-mainpage-block-matches-title'] = 'Матчи',
		['dota2-mainpage-block-partnerWikis-title'] = 'Вики-партнёры',
		['dota2-mainpage-block-tournaments-title'] = 'Турниры',
		['dota2-mainpage-block-rankings-title'] = 'Рейтинги Liquipedia',

		['dota2-mainpage-button-heroes-title'] = 'Герои',
		['dota2-mainpage-button-heroes-link'] = 'Герои',
		['dota2-mainpage-button-items-title'] = 'Предметы',
		['dota2-mainpage-button-items-link'] = 'Предметы',
		['dota2-mainpage-button-mechanics-title'] = 'Механики',
		['dota2-mainpage-button-mechanics-link'] = 'Механики',
		['dota2-mainpage-button-mechanics-category'] = 'Механика',
		['dota2-mainpage-button-cosmetics-title'] = 'Косметика',
		['dota2-mainpage-button-cosmetics-link'] = 'Косметические предметы',
		['dota2-mainpage-button-updates-title'] = 'Обновления',
		['dota2-mainpage-button-updates-link'] = 'Обновления',
		['dota2-mainpage-button-tournaments-title'] = 'Турниры',
		['dota2-mainpage-button-tournaments-link'] = 'Портал:Турниры',
		['dota2-mainpage-button-teams-title'] = 'Команды',
		['dota2-mainpage-button-teams-link'] = 'Портал:Команды',
		['dota2-mainpage-button-players-title'] = 'Игроки',
		['dota2-mainpage-button-players-link'] = 'Портал:Игроки',
		['dota2-mainpage-button-transfers-title'] = 'Трансферы',
		['dota2-mainpage-button-transfers-link'] = 'Портал:Трансферы',
	}
}
