---
-- @Liquipedia
-- wiki=commons
-- page=Module:Flags/MasterData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- There are four tables:
--   data (contains flag images. Should have one entry per image)
--   twoLetter (two-letter country codes as per ISO 3166-1 alpha-2)
--   threeLetter (three-letter country codes)
--   aliases (redirects to the appropriate index in the data table)

-- This table includes:
--   ISO 3166-1 alpha-2
--   ISO 3166-1 alpha-2 User-assigned Code Elements
--   ISO 3166-1 alpha-2 Exceptional Reservations
--   ISO 3166-1 alpha-2 Traditional Reservations
--   ISO 3166-2:GB
--   Other
local data = {
	-- ISO 3166-1 alpha-2
	['andorra'] = {
		name = 'Andorra',
		flag = 'File:ad_hd.png'
	},
	['unitedarabemirates'] = {
		name = 'United Arab Emirates',
		flag = 'File:ae_hd.png'
	},
	['afghanistan'] = {
		name = 'Afghanistan',
		flag = 'File:af_hd.png'
	},
	['antiguaandbarbuda'] = {
		name = 'Antigua and Barbuda',
		flag = 'File:ag_hd.png'
	},
	['anguilla'] = {
		name = 'Anguilla',
		flag = 'File:ai_hd.png'
	},
	['albania'] = {
		name = 'Albania',
		flag = 'File:al_hd.png'
	},
	['armenia'] = {
		name = 'Armenia',
		flag = 'File:am_hd.png'
	},
	['angola'] = {
		name = 'Angola',
		flag = 'File:ao_hd.png'
	},
	['antarctica'] = {
		name = 'Antarctica',
		flag = 'File:aq_hd.png'
	},
	['argentina'] = {
		name = 'Argentina',
		flag = 'File:ar_hd.png'
	},
	['americansamoa'] = {
		name = 'American Samoa',
		flag = 'File:as_hd.png'
	},
	['ascensionisland'] = {
		name = 'Ascension Island',
		flag = 'File:ac_hd.png'
	},
	['austria'] = {
		name = 'Austria',
		flag = 'File:at_hd.png'
	},
	['australia'] = {
		name = 'Australia',
		flag = 'File:au_hd.png'
	},
	['aruba'] = {
		name = 'Aruba',
		flag = 'File:aw_hd.png'
	},
	['ålandislands'] = {
		name = 'Åland Islands',
		flag = 'File:ax_hd.png'
	},
	['azerbaijan'] = {
		name = 'Azerbaijan',
		flag = 'File:az_hd.png'
	},
	['bosniaandherzegovina'] = {
		name = 'Bosnia and Herzegovina',
		flag = 'File:ba_hd.png'
	},
	['barbados'] = {
		name = 'Barbados',
		flag = 'File:bb_hd.png'
	},
	['bangladesh'] = {
		name = 'Bangladesh',
		flag = 'File:bd_hd.png'
	},
	['belgium'] = {
		name = 'Belgium',
		flag = 'File:be_hd.png'
	},
	['burkinafaso'] = {
		name = 'Burkina Faso',
		flag = 'File:bf_hd.png'
	},
	['bulgaria'] = {
		name = 'Bulgaria',
		flag = 'File:bg_hd.png'
	},
	['bahrain'] = {
		name = 'Bahrain',
		flag = 'File:bh_hd.png'
	},
	['burundi'] = {
		name = 'Burundi',
		flag = 'File:bi_hd.png'
	},
	['benin'] = {
		name = 'Benin',
		flag = 'File:bj_hd.png'
	},
	['saintbarthélemy'] = {
		name = 'Saint Barthélemy',
		flag = 'File:bl_hd.png'
	},
	['bermuda'] = {
		name = 'Bermuda',
		flag = 'File:bm_hd.png'
	},
	['brunei'] = {
		name = 'Brunei',
		flag = 'File:bn_hd.png'
	},
	['bolivia'] = {
		name = 'Bolivia',
		flag = 'File:bo_hd.png'
	},
	['bonaire,sinteustatiusandsaba'] = {
		name = 'Bonaire, Sint Eustatius and Saba',
		flag = 'File:bq_hd.png'
	},
	['brazil'] = {
		name = 'Brazil',
		flag = 'File:br_hd.png'
	},
	['bahamas'] = {
		name = 'Bahamas',
		flag = 'File:bs_hd.png'
	},
	['bhutan'] = {
		name = 'Bhutan',
		flag = 'File:bt_hd.png'
	},
	['bouvetisland'] = {
		name = 'Bouvet Island',
		flag = 'File:bv_hd.png'
	},
	['botswana'] = {
		name = 'Botswana',
		flag = 'File:bw_hd.png'
	},
	['belarus'] = {
		name = 'Belarus',
		flag = 'File:by_hd.png'
	},
	['belize'] = {
		name = 'Belize',
		flag = 'File:bz_hd.png'
	},
	['canada'] = {
		name = 'Canada',
		flag = 'File:ca_hd.png'
	},
	['cocos(keeling)islands'] = {
		name = 'Cocos (Keeling) Islands',
		flag = 'File:cc_hd.png'
	},
	['congo,democraticrepublicofthe'] = {
		name = 'Democratic Republic of the Congo',
		flag = 'File:cd_hd.png'
	},
	['centralafricanrepublic'] = {
		name = 'Central African Republic',
		flag = 'File:cf_hd.png'
	},
	['congo'] = {
		name = 'Congo',
		flag = 'File:cg_hd.png'
	},
	['switzerland'] = {
		name = 'Switzerland',
		flag = 'File:ch_hd.png'
	},
	["côted'ivoire"] = {
		name = "Côte d'Ivoire",
		flag = 'File:ci_hd.png'
	},
	['cookislands'] = {
		name = 'Cook Islands',
		flag = 'File:ck_hd.png'
	},
	['chile'] = {
		name = 'Chile',
		flag = 'File:cl_hd.png'
	},
	['cameroon'] = {
		name = 'Cameroon',
		flag = 'File:cm_hd.png'
	},
	['china'] = {
		name = 'China',
		flag = 'File:cn_hd.png'
	},
	['colombia'] = {
		name = 'Colombia',
		flag = 'File:co_hd.png'
	},
	['costarica'] = {
		name = 'Costa Rica',
		flag = 'File:cr_hd.png'
	},
	['cuba'] = {
		name = 'Cuba',
		flag = 'File:cu_hd.png'
	},
	['caboverde'] = {
		name = 'Cabo Verde',
		flag = 'File:cv_hd.png'
	},
	['curaçao'] = {
		name = 'Curaçao',
		flag = 'File:cw_hd.png'
	},
	['christmasisland'] = {
		name = 'Christmas Island',
		flag = 'File:cx_hd.png'
	},
	['cyprus'] = {
		name = 'Cyprus',
		flag = 'File:cy_hd.png'
	},
	['czechia'] = {
		name = 'Czechia',
		flag = 'File:cz_hd.png'
	},
	['germany'] = {
		name = 'Germany',
		flag = 'File:de_hd.png'
	},
	['djibouti'] = {
		name = 'Djibouti',
		flag = 'File:dj_hd.png'
	},
	['denmark'] = {
		name = 'Denmark',
		flag = 'File:dk_hd.png'
	},
	['dominica'] = {
		name = 'Dominica',
		flag = 'File:dm_hd.png'
	},
	['dominicanrepublic'] = {
		name = 'Dominican Republic',
		flag = 'File:do_hd.png'
	},
	['algeria'] = {
		name = 'Algeria',
		flag = 'File:dz_hd.png'
	},
	['ecuador'] = {
		name = 'Ecuador',
		flag = 'File:ec_hd.png'
	},
	['estonia'] = {
		name = 'Estonia',
		flag = 'File:ee_hd.png'
	},
	['egypt'] = {
		name = 'Egypt',
		flag = 'File:eg_hd.png'
	},
	['westernsahara'] = {
		name = 'Western Sahara',
		flag = 'File:eh_hd.png'
	},
	['eritrea'] = {
		name = 'Eritrea',
		flag = 'File:er_hd.png'
	},
	['spain'] = {
		name = 'Spain',
		flag = 'File:es_hd.png'
	},
	['ethiopia'] = {
		name = 'Ethiopia',
		flag = 'File:et_hd.png'
	},
	['finland'] = {
		name = 'Finland',
		flag = 'File:fi_hd.png'
	},
	['fiji'] = {
		name = 'Fiji',
		flag = 'File:fj_hd.png'
	},
	['falklandislands'] = {
		name = 'Falkland Islands',
		flag = 'File:fk_hd.png'
	},
	['federatedstatesofmicronesia'] = {
		name = 'Federated States of Micronesia',
		flag = 'File:fm_hd.png'
	},
	['faroeislands'] = {
		name = 'Faroe Islands',
		flag = 'File:fo_hd.png'
	},
	['france'] = {
		name = 'France',
		flag = 'File:fr_hd.png'
	},
	['gabon'] = {
		name = 'Gabon',
		flag = 'File:ga_hd.png'
	},
	['unitedkingdom'] = {
		name = 'United Kingdom',
		flag = 'File:gb_hd.png'
	},
	['grenada'] = {
		name = 'Grenada',
		flag = 'File:gd_hd.png'
	},
	['georgia'] = {
		name = 'Georgia',
		flag = 'File:ge_hd.png'
	},
	['frenchguiana'] = {
		name = 'French Guiana',
		flag = 'File:gf_hd.png'
	},
	['guernsey'] = {
		name = 'Guernsey',
		flag = 'File:gg_hd.png'
	},
	['ghana'] = {
		name = 'Ghana',
		flag = 'File:gh_hd.png'
	},
	['gibraltar'] = {
		name = 'Gibraltar',
		flag = 'File:gi_hd.png'
	},
	['greenland'] = {
		name = 'Greenland',
		flag = 'File:gl_hd.png'
	},
	['gambia'] = {
		name = 'Gambia',
		flag = 'File:gm_hd.png'
	},
	['guinea'] = {
		name = 'Guinea',
		flag = 'File:gn_hd.png'
	},
	['guadeloupe'] = {
		name = 'Guadeloupe',
		flag = 'File:gp_hd.png'
	},
	['equatorialguinea'] = {
		name = 'Equatorial Guinea',
		flag = 'File:gq_hd.png'
	},
	['greece'] = {
		name = 'Greece',
		flag = 'File:gr_hd.png'
	},
	['southgeorgiaandthesouthsandwichislands'] = {
		name = 'South Georgia and the South Sandwich Islands',
		flag = 'File:gs_hd.png'
	},
	['guatemala'] = {
		name = 'Guatemala',
		flag = 'File:gt_hd.png'
	},
	['guam'] = {
		name = 'Guam',
		flag = 'File:gu_hd.png'
	},
	['guinea-bissau'] = {
		name = 'Guinea-Bissau',
		flag = 'File:gw_hd.png'
	},
	['guyana'] = {
		name = 'Guyana',
		flag = 'File:gy_hd.png'
	},
	['hongkong'] = {
		name = 'Hong Kong',
		flag = 'File:hk_hd.png'
	},
	['heardislandandmcdonaldislands'] = {
		name = 'Heard Island and McDonald Islands',
		flag = 'File:hm_hd.png'
	},
	['honduras'] = {
		name = 'Honduras',
		flag = 'File:hn_hd.png'
	},
	['croatia'] = {
		name = 'Croatia',
		flag = 'File:hr_hd.png'
	},
	['haiti'] = {
		name = 'Haiti',
		flag = 'File:ht_hd.png'
	},
	['hungary'] = {
		name = 'Hungary',
		flag = 'File:hu_hd.png'
	},
	['indonesia'] = {
		name = 'Indonesia',
		flag = 'File:id_hd.png'
	},
	['ireland'] = {
		name = 'Ireland',
		flag = 'File:ie_hd.png'
	},
	['israel'] = {
		name = 'Israel',
		flag = 'File:il_hd.png'
	},
	['isleofman'] = {
		name = 'Isle of Man',
		flag = 'File:im_hd.png'
	},
	['india'] = {
		name = 'India',
		flag = 'File:in_hd.png'
	},
	['britishindianoceanterritory'] = {
		name = 'British Indian Ocean Territory',
		flag = 'File:io_hd.png'
	},
	['iraq'] = {
		name = 'Iraq',
		flag = 'File:iq_hd.png'
	},
	['iran'] = {
		name = 'Iran',
		flag = 'File:ir_hd.png'
	},
	['iceland'] = {
		name = 'Iceland',
		flag = 'File:is_hd.png'
	},
	['italy'] = {
		name = 'Italy',
		flag = 'File:it_hd.png'
	},
	['jersey'] = {
		name = 'Jersey',
		flag = 'File:je_hd.png'
	},
	['jamaica'] = {
		name = 'Jamaica',
		flag = 'File:jm_hd.png'
	},
	['jordan'] = {
		name = 'Jordan',
		flag = 'File:jo_hd.png'
	},
	['japan'] = {
		name = 'Japan',
		flag = 'File:jp_hd.png'
	},
	['kenya'] = {
		name = 'Kenya',
		flag = 'File:ke_hd.png'
	},
	['kyrgyzstan'] = {
		name = 'Kyrgyzstan',
		flag = 'File:kg_hd.png'
	},
	['cambodia'] = {
		name = 'Cambodia',
		flag = 'File:kh_hd.png'
	},
	['kiribati'] = {
		name = 'Kiribati',
		flag = 'File:ki_hd.png'
	},
	['comoros'] = {
		name = 'Comoros',
		flag = 'File:km_hd.png'
	},
	['saintkittsandnevis'] = {
		name = 'Saint Kitts and Nevis',
		flag = 'File:kn_hd.png'
	},
	['northkorea'] = {
		name = 'North Korea',
		flag = 'File:kp_hd.png'
	},
	['southkorea'] = {
		name = 'South Korea',
		flag = 'File:kr_hd.png'
	},
	['kuwait'] = {
		name = 'Kuwait',
		flag = 'File:kw_hd.png'
	},
	['caymanislands'] = {
		name = 'Cayman Islands',
		flag = 'File:ky_hd.png'
	},
	['kazakhstan'] = {
		name = 'Kazakhstan',
		flag = 'File:kz_hd.png'
	},
	['laos'] = {
		name = 'Laos',
		flag = 'File:la_hd.png'
	},
	['lebanon'] = {
		name = 'Lebanon',
		flag = 'File:lb_hd.png'
	},
	['saintlucia'] = {
		name = 'Saint Lucia',
		flag = 'File:lc_hd.png'
	},
	['liechtenstein'] = {
		name = 'Liechtenstein',
		flag = 'File:li_hd.png'
	},
	['srilanka'] = {
		name = 'Sri Lanka',
		flag = 'File:lk_hd.png'
	},
	['liberia'] = {
		name = 'Liberia',
		flag = 'File:lr_hd.png'
	},
	['lesotho'] = {
		name = 'Lesotho',
		flag = 'File:ls_hd.png'
	},
	['lithuania'] = {
		name = 'Lithuania',
		flag = 'File:lt_hd.png'
	},
	['luxembourg'] = {
		name = 'Luxembourg',
		flag = 'File:lu_hd.png'
	},
	['latvia'] = {
		name = 'Latvia',
		flag = 'File:lv_hd.png'
	},
	['libya'] = {
		name = 'Libya',
		flag = 'File:ly_hd.png'
	},
	['morocco'] = {
		name = 'Morocco',
		flag = 'File:ma_hd.png'
	},
	['monaco'] = {
		name = 'Monaco',
		flag = 'File:mc_hd.png'
	},
	['moldova'] = {
		name = 'Moldova',
		flag = 'File:md_hd.png'
	},
	['montenegro'] = {
		name = 'Montenegro',
		flag = 'File:me_hd.png'
	},
	['saintmartin(frenchpart)'] = {
		name = 'Saint Martin (French part)',
		flag = 'File:mf_hd.png'
	},
	['madagascar'] = {
		name = 'Madagascar',
		flag = 'File:mg_hd.png'
	},
	['marshallislands'] = {
		name = 'Marshall Islands',
		flag = 'File:mh_hd.png'
	},
	['northmacedonia'] = {
		name = 'North Macedonia',
		flag = 'File:mk_hd.png'
	},
	['mali'] = {
		name = 'Mali',
		flag = 'File:ml_hd.png'
	},
	['myanmar'] = {
		name = 'Myanmar',
		flag = 'File:mm_hd.png'
	},
	['mongolia'] = {
		name = 'Mongolia',
		flag = 'File:mn_hd.png'
	},
	['macau'] = {
		name = 'Macau',
		flag = 'File:mo_hd.png'
	},
	['northernmarianaislands'] = {
		name = 'Northern Mariana Islands',
		flag = 'File:mp_hd.png'
	},
	['martinique'] = {
		name = 'Martinique',
		flag = 'File:mq_hd.png'
	},
	['mauritania'] = {
		name = 'Mauritania',
		flag = 'File:mr_hd.png'
	},
	['montserrat'] = {
		name = 'Montserrat',
		flag = 'File:ms_hd.png'
	},
	['malta'] = {
		name = 'Malta',
		flag = 'File:mt_hd.png'
	},
	['mauritius'] = {
		name = 'Mauritius',
		flag = 'File:mu_hd.png'
	},
	['maldives'] = {
		name = 'Maldives',
		flag = 'File:mv_hd.png'
	},
	['malawi'] = {
		name = 'Malawi',
		flag = 'File:mw_hd.png'
	},
	['mexico'] = {
		name = 'Mexico',
		flag = 'File:mx_hd.png'
	},
	['malaysia'] = {
		name = 'Malaysia',
		flag = 'File:my_hd.png'
	},
	['mozambique'] = {
		name = 'Mozambique',
		flag = 'File:mz_hd.png'
	},
	['namibia'] = {
		name = 'Namibia',
		flag = 'File:na_hd.png'
	},
	['newcaledonia'] = {
		name = 'New Caledonia',
		flag = 'File:nc_hd.png'
	},
	['niger'] = {
		name = 'Niger',
		flag = 'File:ne_hd.png'
	},
	['norfolkisland'] = {
		name = 'Norfolk Island',
		flag = 'File:nf_hd.png'
	},
	['nigeria'] = {
		name = 'Nigeria',
		flag = 'File:ng_hd.png'
	},
	['nicaragua'] = {
		name = 'Nicaragua',
		flag = 'File:ni_hd.png'
	},
	['netherlands'] = {
		name = 'Netherlands',
		flag = 'File:nl_hd.png'
	},
	['norway'] = {
		name = 'Norway',
		flag = 'File:no_hd.png'
	},
	['nepal'] = {
		name = 'Nepal',
		flag = 'File:np_hd.png'
	},
	['nauru'] = {
		name = 'Nauru',
		flag = 'File:nr_hd.png'
	},
	['niue'] = {
		name = 'Niue',
		flag = 'File:nu_hd.png'
	},
	['newzealand'] = {
		name = 'New Zealand',
		flag = 'File:nz_hd.png'
	},
	['oman'] = {
		name = 'Oman',
		flag = 'File:om_hd.png'
	},
	['panama'] = {
		name = 'Panama',
		flag = 'File:pa_hd.png'
	},
	['peru'] = {
		name = 'Peru',
		flag = 'File:pe_hd.png'
	},
	['frenchpolynesia'] = {
		name = 'French Polynesia',
		flag = 'File:pf_hd.png'
	},
	['papuanewguinea'] = {
		name = 'Papua New Guinea',
		flag = 'File:pg_hd.png'
	},
	['philippines'] = {
		name = 'Philippines',
		flag = 'File:ph_hd.png'
	},
	['pakistan'] = {
		name = 'Pakistan',
		flag = 'File:pk_hd.png'
	},
	['poland'] = {
		name = 'Poland',
		flag = 'File:pl_hd.png'
	},
	['saintpierreandmiquelon'] = {
		name = 'Saint Pierre and Miquelon',
		flag = 'File:pm_hd.png'
	},
	['pitcairn'] = {
		name = 'Pitcairn',
		flag = 'File:pn_hd.png'
	},
	['puertorico'] = {
		name = 'Puerto Rico',
		flag = 'File:pr_hd.png'
	},
	['palestine'] = {
		name = 'Palestine',
		flag = 'File:ps_hd.png'
	},
	['portugal'] = {
		name = 'Portugal',
		flag = 'File:pt_hd.png'
	},
	['palau'] = {
		name = 'Palau',
		flag = 'File:pw_hd.png'
	},
	['paraguay'] = {
		name = 'Paraguay',
		flag = 'File:py_hd.png'
	},
	['qatar'] = {
		name = 'Qatar',
		flag = 'File:qa_hd.png'
	},
	['réunion'] = {
		name = 'Réunion',
		flag = 'File:re_hd.png'
	},
	['romania'] = {
		name = 'Romania',
		flag = 'File:ro_hd.png'
	},
	['serbia'] = {
		name = 'Serbia',
		flag = 'File:rs_hd.png'
	},
	['russia'] = {
		name = 'Russia',
		flag = 'File:ru_hd.png'
	},
	['rwanda'] = {
		name = 'Rwanda',
		flag = 'File:rw_hd.png'
	},
	['saudiarabia'] = {
		name = 'Saudi Arabia',
		flag = 'File:sa_hd.png'
	},
	['solomonislands'] = {
		name = 'Solomon Islands',
		flag = 'File:sb_hd.png'
	},
	['seychelles'] = {
		name = 'Seychelles',
		flag = 'File:sc_hd.png'
	},
	['sudan'] = {
		name = 'Sudan',
		flag = 'File:sd_hd.png'
	},
	['sweden'] = {
		name = 'Sweden',
		flag = 'File:se_hd.png'
	},
	['singapore'] = {
		name = 'Singapore',
		flag = 'File:sg_hd.png'
	},
	['sainthelena'] = {
		name = 'Saint Helena',
		flag = 'File:sh_hd.png'
	},
	['slovenia'] = {
		name = 'Slovenia',
		flag = 'File:si_hd.png'
	},
	['svalbardandjanmayen'] = {
		name = 'Svalbard and Jan Mayen',
		flag = 'File:sj_hd.png'
	},
	['slovakia'] = {
		name = 'Slovakia',
		flag = 'File:sk_hd.png'
	},
	['sierraleone'] = {
		name = 'Sierra Leone',
		flag = 'File:sl_hd.png'
	},
	['sanmarino'] = {
		name = 'San Marino',
		flag = 'File:sm_hd.png'
	},
	['senegal'] = {
		name = 'Senegal',
		flag = 'File:sn_hd.png'
	},
	['somalia'] = {
		name = 'Somalia',
		flag = 'File:so_hd.png'
	},
	['suriname'] = {
		name = 'Suriname',
		flag = 'File:sr_hd.png'
	},
	['southsudan'] = {
		name = 'South Sudan',
		flag = 'File:ss_hd.png'
	},
	['saotomeandprincipe'] = {
		name = 'Sao Tome and Principe',
		flag = 'File:st_hd.png'
	},
	['elsalvador'] = {
		name = 'El Salvador',
		flag = 'File:sv_hd.png'
	},
	['sintmaarten(dutchpart)'] = {
		name = 'Sint Maarten (Dutch part)',
		flag = 'File:sx_hd.png'
	},
	['syria'] = {
		name = 'Syria',
		flag = 'File:sy_hd.png'
	},
	['eswatini'] = {
		name = 'Eswatini',
		flag = 'File:sz_hd.png'
	},
	['turksandcaicosislands'] = {
		name = 'Turks and Caicos Islands',
		flag = 'File:tc_hd.png'
	},
	['chad'] = {
		name = 'Chad',
		flag = 'File:td_hd.png'
	},
	['frenchsouthernterritories'] = {
		name = 'French Southern Territories',
		flag = 'File:tf_hd.png'
	},
	['togo'] = {
		name = 'Togo',
		flag = 'File:tg_hd.png'
	},
	['thailand'] = {
		name = 'Thailand',
		flag = 'File:th_hd.png'
	},
	['tajikistan'] = {
		name = 'Tajikistan',
		flag = 'File:tj_hd.png'
	},
	['tokelau'] = {
		name = 'Tokelau',
		flag = 'File:tk_hd.png'
	},
	['timor-leste'] = {
		name = 'Timor-Leste',
		flag = 'File:tl_hd.png'
	},
	['turkmenistan'] = {
		name = 'Turkmenistan',
		flag = 'File:tm_hd.png'
	},
	['tunisia'] = {
		name = 'Tunisia',
		flag = 'File:tn_hd.png'
	},
	['tonga'] = {
		name = 'Tonga',
		flag = 'File:to_hd.png'
	},
	['turkey'] = {
		name = 'Turkey',
		flag = 'File:tr_hd.png'
	},
	['tristandacunha'] = {
		name = 'Tristan da Cunha',
		flag = 'File:sh-ta hd.png'
	},
	['trinidadandtobago'] = {
		name = 'Trinidad and Tobago',
		flag = 'File:tt_hd.png'
	},
	['tuvalu'] = {
		name = 'Tuvalu',
		flag = 'File:tv_hd.png'
	},
	['taiwan'] = {
		name = 'Taiwan',
		flag = 'File:tw_hd.png'
	},
	['tanzania'] = {
		name = 'Tanzania',
		flag = 'File:tz_hd.png'
	},
	['ukraine'] = {
		name = 'Ukraine',
		flag = 'File:ua_hd.png'
	},
	['uganda'] = {
		name = 'Uganda',
		flag = 'File:ug_hd.png'
	},
	['unitedstatesminoroutlyingislands'] = {
		name = 'United States Minor Outlying Islands',
		flag = 'File:um_hd.png'
	},
	['unitedstates'] = {
		name = 'United States',
		flag = 'File:us_hd.png'
	},
	['uruguay'] = {
		name = 'Uruguay',
		flag = 'File:uy_hd.png'
	},
	['uzbekistan'] = {
		name = 'Uzbekistan',
		flag = 'File:uz_hd.png'
	},
	['vaticancity'] = {
		name = 'Vatican City',
		flag = 'File:va_hd.png'
	},
	['saintvincentandthegrenadines'] = {
		name = 'Saint Vincent and the Grenadines',
		flag = 'File:vc_hd.png'
	},
	['venezuela'] = {
		name = 'Venezuela',
		flag = 'File:ve_hd.png'
	},
	['virginislands(british)'] = {
		name = 'Virgin Islands (British)',
		flag = 'File:vg_hd.png'
	},
	['virginislands(u.s.)'] = {
		name = 'Virgin Islands (U.S.)',
		flag = 'File:vi_hd.png'
	},
	['vietnam'] = {
		name = 'Vietnam',
		flag = 'File:vn_hd.png'
	},
	['vanuatu'] = {
		name = 'Vanuatu',
		flag = 'File:vu_hd.png'
	},
	['wallisandfutuna'] = {
		name = 'Wallis and Futuna',
		flag = 'File:wf_hd.png'
	},
	['samoa'] = {
		name = 'Samoa',
		flag = 'File:ws_hd.png'
	},
	['yemen'] = {
		name = 'Yemen',
		flag = 'File:ye_hd.png'
	},
	['mayotte'] = {
		name = 'Mayotte',
		flag = 'File:yt_hd.png'
	},
	['southafrica'] = {
		name = 'South Africa',
		flag = 'File:za_hd.png'
	},
	['zambia'] = {
		name = 'Zambia',
		flag = 'File:zm_hd.png'
	},
	['zimbabwe'] = {
		name = 'Zimbabwe',
		flag = 'File:zw_hd.png'
	},

	-- ISO 3166-1 alpha-2 User-assigned Code Elements
	['kosovo'] = {
		name = 'Kosovo',
		flag = 'File:xk_hd.png'
	},

	-- ISO 3166-1 alpha-2 Exceptional Reservations
	['europeanunion'] = {
		name = 'Europe',
		flag = 'File:eu_hd.png'
	},
	['unitednations'] = {
		name = 'United Nations',
		flag = 'File:un_hd.png'
	},
	['ussr'] = {
		name = 'USSR',
		flag = 'File:ussr_hd.png'
	},

	-- ISO 3166-1 alpha-2 Traditional Reservations
	['yugoslavia'] = {
		name = 'Yugoslavia',
		flag = 'File:yu_hd.png'
	},

	-- ISO 3166-2:GB
	['england'] = {
		name = 'England',
		flag = 'File:gb-eng hd.png'
	},
	['northernireland'] = {
		name = 'Northern Ireland',
		flag = 'File:gb-nir hd.png'
	},
	['scotland'] = {
		name = 'Scotland',
		flag = 'File:gb-sct hd.png'
	},
	['wales'] = {
		name = 'Wales',
		flag = 'File:gb-wls hd.png'
	},

	-- Other
	['africa'] = {
		name = 'Africa',
		flag = 'File:african union hd.png'
	},
	['americas'] = {
		name = 'Americas',
		flag = 'File:UsCa hd.png'
	},
	['asia'] = {
		name = 'Asia',
		flag = 'File:Asia flag hd.png'
	},
	['benelux'] = {
		name = 'Benelux',
		flag = 'File:benelux hd.png'
	},
	['centralamerica'] = {
		name = 'Central America',
		flag = 'File:cais flag hd.png'
	},
	['commonwealthofindependentstates'] = {
		name = 'CIS',
		flag = 'File:Cis hd.png'
	},
	['eastasia'] = {
		name = 'East Asia',
		flag = 'File:East asia flag hd.png'
	},
	['iberia'] = {
		name = 'Iberia',
		flag = 'File:EsPt hd.png'
	},
	['northamerica'] = {
		name = 'North America',
		flag = 'File:UsCa hd.png'
	},
	['middleeast'] = {
		name = 'Middle East',
		flag = 'File:Middle east flag hd.png'
	},
	['nordiccountries'] = {
		name = 'Nordic Countries',
		flag = 'File:Nordic hd.png'
	},
	['northafrica'] = {
		name = 'North Africa',
		flag = 'File:Space filler flag.png'
	},
	['oceania'] = {
		name = 'Oceania',
		flag = 'File:anz hd.png'
	},
	['southamerica'] = {
		name = 'South America',
		flag = 'File:Unasur hd.png'
	},
	['southasia'] = {
		name = 'South Asia',
		flag = 'File:south asia flag hd.png'
	},
	['southeastasia'] = {
		name = 'Southeast Asia',
		flag = 'File:asean hd.png'
	},
	['world'] = {
		name = 'World',
		flag = 'File:World hd.png'
	},
	['englishspeaking'] = {
		name = 'English Speaking',
		flag = 'File:UsGb hd.png'
	},
	['germanspeaking'] = {
		name = 'German Speaking',
		flag = 'File:DeAt hd.png'
	},
	['spanishspeaking'] = {
		name = 'Spanish Speaking',
		flag = 'File:EsMx hd.png'
	},
	['portuguesespeaking'] = {
		name = 'Portuguese Speaking',
		flag = 'File:PtBr hd.png'
	},
	['russianspeaking'] = {
		name = 'Russian Speaking',
		flag = 'File:RuBy hd.png'
	},
	['non-representing'] = {
		name = 'Non-representing',
		flag = 'File:non hd.png'
	},
	['filler'] = {
		name = '',
		flag = 'File:Space filler flag.png'
	},
}

-- This table includes:
--   ISO 3166-1 alpha-2
--   ISO 3166-1 alpha-2 User-assigned Code Elements
--   ISO 3166-1 alpha-2 Exceptional Reservations
--   ISO 3166-1 alpha-2 Traditional Reservations
local twoLetter = {
	['ad'] = 'andorra',
	['ae'] = 'unitedarabemirates',
	['af'] = 'afghanistan',
	['ag'] = 'antiguaandbarbuda',
	['ai'] = 'anguilla',
	['al'] = 'albania',
	['am'] = 'armenia',
	['ao'] = 'angola',
	['aq'] = 'antarctica',
	['ar'] = 'argentina',
	['as'] = 'americansamoa',
	['ac'] = 'ascensionisland',
	['at'] = 'austria',
	['au'] = 'australia',
	['aw'] = 'aruba',
	['ax'] = 'ålandislands',
	['az'] = 'azerbaijan',
	['ba'] = 'bosniaandherzegovina',
	['bb'] = 'barbados',
	['bd'] = 'bangladesh',
	['be'] = 'belgium',
	['bf'] = 'burkinafaso',
	['bg'] = 'bulgaria',
	['bh'] = 'bahrain',
	['bi'] = 'burundi',
	['bj'] = 'benin',
	['bl'] = 'saintbarthélemy',
	['bm'] = 'bermuda',
	['bn'] = 'brunei',
	['bo'] = 'bolivia',
	['bq'] = 'bonaire,sinteustatiusandsaba',
	['br'] = 'brazil',
	['bs'] = 'bahamas',
	['bt'] = 'bhutan',
	['bv'] = 'bouvetisland',
	['bw'] = 'botswana',
	['by'] = 'belarus',
	['bz'] = 'belize',
	['ca'] = 'canada',
	['cc'] = 'cocos(keeling)islands',
	['cd'] = 'congo,democraticrepublicofthe',
	['cf'] = 'centralafricanrepublic',
	['cg'] = 'congo',
	['ch'] = 'switzerland',
	['ci'] = "côted'ivoire",
	['ck'] = 'cookislands',
	['cl'] = 'chile',
	['cm'] = 'cameroon',
	['cn'] = 'china',
	['co'] = 'colombia',
	['cr'] = 'costarica',
	['cu'] = 'cuba',
	['cv'] = 'caboverde',
	['cw'] = 'curaçao',
	['cx'] = 'christmasisland',
	['cy'] = 'cyprus',
	['cz'] = 'czechia',
	['de'] = 'germany',
	['dj'] = 'djibouti',
	['dk'] = 'denmark',
	['dm'] = 'dominica',
	['do'] = 'dominicanrepublic',
	['dz'] = 'algeria',
	['ec'] = 'ecuador',
	['ee'] = 'estonia',
	['eg'] = 'egypt',
	['eh'] = 'westernsahara',
	['er'] = 'eritrea',
	['es'] = 'spain',
	['et'] = 'ethiopia',
	['fi'] = 'finland',
	['fj'] = 'fiji',
	['fk'] = 'falklandislands',
	['fm'] = 'micronesia',
	['fo'] = 'faroeislands',
	['fr'] = 'france',
	['ga'] = 'gabon',
	['gb'] = 'unitedkingdom',
	['gd'] = 'grenada',
	['ge'] = 'georgia',
	['gf'] = 'frenchguiana',
	['gg'] = 'guernsey',
	['gh'] = 'ghana',
	['gi'] = 'gibraltar',
	['gl'] = 'greenland',
	['gm'] = 'gambia',
	['gn'] = 'guinea',
	['gp'] = 'guadeloupe',
	['gq'] = 'equatorialguinea',
	['gr'] = 'greece',
	['gs'] = 'southgeorgiaandthesouthsandwichislands',
	['gt'] = 'guatemala',
	['gu'] = 'guam',
	['gw'] = 'guinea-bissau',
	['gy'] = 'guyana',
	['hk'] = 'hongkong',
	['hm'] = 'heardislandandmcdonaldislands',
	['hn'] = 'honduras',
	['hr'] = 'croatia',
	['ht'] = 'haiti',
	['hu'] = 'hungary',
	['id'] = 'indonesia',
	['ie'] = 'ireland',
	['il'] = 'israel',
	['im'] = 'isleofman',
	['in'] = 'india',
	['io'] = 'britishindianoceanterritory',
	['iq'] = 'iraq',
	['ir'] = 'iran',
	['is'] = 'iceland',
	['it'] = 'italy',
	['je'] = 'jersey',
	['jm'] = 'jamaica',
	['jo'] = 'jordan',
	['jp'] = 'japan',
	['ke'] = 'kenya',
	['kg'] = 'kyrgyzstan',
	['kh'] = 'cambodia',
	['ki'] = 'kiribati',
	['km'] = 'comoros',
	['kn'] = 'saintkittsandnevis',
	['kp'] = 'northkorea',
	['kr'] = 'southkorea',
	['kw'] = 'kuwait',
	['ky'] = 'caymanislands',
	['kz'] = 'kazakhstan',
	['la'] = 'laos',
	['lb'] = 'lebanon',
	['lc'] = 'saintlucia',
	['li'] = 'liechtenstein',
	['lk'] = 'srilanka',
	['lr'] = 'liberia',
	['ls'] = 'lesotho',
	['lt'] = 'lithuania',
	['lu'] = 'luxembourg',
	['lv'] = 'latvia',
	['ly'] = 'libya',
	['ma'] = 'morocco',
	['mc'] = 'monaco',
	['md'] = 'moldova',
	['me'] = 'montenegro',
	['mf'] = 'saintmartin(frenchpart)',
	['mg'] = 'madagascar',
	['mh'] = 'marshallislands',
	['mk'] = 'northmacedonia',
	['ml'] = 'mali',
	['mm'] = 'myanmar',
	['mn'] = 'mongolia',
	['mo'] = 'macau',
	['mp'] = 'northernmarianaislands',
	['mq'] = 'martinique',
	['mr'] = 'mauritania',
	['ms'] = 'montserrat',
	['mt'] = 'malta',
	['mu'] = 'mauritius',
	['mv'] = 'maldives',
	['mw'] = 'malawi',
	['mx'] = 'mexico',
	['my'] = 'malaysia',
	['mz'] = 'mozambique',
	['na'] = 'namibia',
	['nc'] = 'newcaledonia',
	['ne'] = 'niger',
	['nf'] = 'norfolkisland',
	['ng'] = 'nigeria',
	['ni'] = 'nicaragua',
	['nl'] = 'netherlands',
	['no'] = 'norway',
	['np'] = 'nepal',
	['nr'] = 'nauru',
	['nu'] = 'niue',
	['nz'] = 'newzealand',
	['om'] = 'oman',
	['pa'] = 'panama',
	['pe'] = 'peru',
	['pf'] = 'frenchpolynesia',
	['pg'] = 'papuanewguinea',
	['ph'] = 'philippines',
	['pk'] = 'pakistan',
	['pl'] = 'poland',
	['pm'] = 'saintpierreandmiquelon',
	['pn'] = 'pitcairn',
	['pr'] = 'puertorico',
	['ps'] = 'palestine',
	['pt'] = 'portugal',
	['pw'] = 'palau',
	['py'] = 'paraguay',
	['qa'] = 'qatar',
	['re'] = 'réunion',
	['ro'] = 'romania',
	['rs'] = 'serbia',
	['ru'] = 'russia',
	['rw'] = 'rwanda',
	['sa'] = 'saudiarabia',
	['sb'] = 'solomonislands',
	['sc'] = 'seychelles',
	['sd'] = 'sudan',
	['se'] = 'sweden',
	['sg'] = 'singapore',
	['sh'] = 'sainthelena',
	['si'] = 'slovenia',
	['sj'] = 'svalbardandjanmayen',
	['sk'] = 'slovakia',
	['sl'] = 'sierraleone',
	['sm'] = 'sanmarino',
	['sn'] = 'senegal',
	['so'] = 'somalia',
	['sr'] = 'suriname',
	['ss'] = 'southsudan',
	['st'] = 'saotomeandprincipe',
	['sv'] = 'elsalvador',
	['sx'] = 'sintmaarten(dutchpart)',
	['sy'] = 'syria',
	['sz'] = 'eswatini',
	['tc'] = 'turksandcaicosislands',
	['td'] = 'chad',
	['tf'] = 'frenchsouthernterritories',
	['tg'] = 'togo',
	['th'] = 'thailand',
	['tj'] = 'tajikistan',
	['tk'] = 'tokelau',
	['tl'] = 'timor-leste',
	['tm'] = 'turkmenistan',
	['tn'] = 'tunisia',
	['to'] = 'tonga',
	['tr'] = 'turkey',
	['tt'] = 'trinidadandtobago',
	['tv'] = 'tuvalu',
	['tw'] = 'taiwan',
	['tz'] = 'tanzania',
	['ua'] = 'ukraine',
	['ug'] = 'uganda',
	['um'] = 'unitedstatesminoroutlyingislands',
	['us'] = 'unitedstates',
	['uy'] = 'uruguay',
	['uz'] = 'uzbekistan',
	['va'] = 'vaticancity',
	['vc'] = 'saintvincentandthegrenadines',
	['ve'] = 'venezuela',
	['vg'] = 'virginislands(british)',
	['vi'] = 'virginislands(u.s.)',
	['vn'] = 'vietnam',
	['vu'] = 'vanuatu',
	['wf'] = 'wallisandfutuna',
	['ws'] = 'samoa',
	['ye'] = 'yemen',
	['yt'] = 'mayotte',
	['za'] = 'southafrica',
	['zm'] = 'zambia',
	['zw'] = 'zimbabwe',

	--   ISO 3166-1 alpha-2 User-assigned Code Elements
	['xk'] = 'kosovo',
	['xx'] = 'non-representing',

	--   ISO 3166-1 alpha-2 Exceptional Reservations
	['eu'] = 'europeanunion',
	['uk'] = 'unitedkingdom',
	['un'] = 'unitednations',

	--   ISO 3166-1 alpha-2 Traditional Reservations
	['yu'] = 'yugoslavia',
}

-- This table includes:
--   ISO 3166-1 alpha-3
--   ISO 3166-2:GB
--   Other
local threeLetter = {
	-- ISO 3166-1 alpha-3
	['abw'] = 'aruba',
	['afg'] = 'afghanistan',
	['ago'] = 'angola',
	['aia'] = 'anguilla',
	['ala'] = 'ålandislands',
	['alb'] = 'albania',
	['and'] = 'andorra',
	['are'] = 'unitedarabemirates',
	['arg'] = 'argentina',
	['arm'] = 'armenia',
	['asm'] = 'americansamoa',
	['ata'] = 'antarctica',
	['atf'] = 'frenchsouthernterritories',
	['atg'] = 'antiguaandbarbuda',
	['aus'] = 'australia',
	['aut'] = 'austria',
	['aze'] = 'azerbaijan',
	['bdi'] = 'burundi',
	['bel'] = 'belgium',
	['ben'] = 'benin',
	['bes'] = 'bonaire,sinteustatiusandsaba',
	['bfa'] = 'burkinafaso',
	['bgd'] = 'bangladesh',
	['bgr'] = 'bulgaria',
	['bhr'] = 'bahrain',
	['bhs'] = 'bahamas',
	['bih'] = 'bosniaandherzegovina',
	['blm'] = 'saintbarthélemy',
	['blr'] = 'belarus',
	['blz'] = 'belize',
	['bmu'] = 'bermuda',
	['bol'] = 'bolivia',
	['bra'] = 'brazil',
	['brb'] = 'barbados',
	['brn'] = 'brunei',
	['btn'] = 'bhutan',
	['bvt'] = 'bouvetisland',
	['bwa'] = 'botswana',
	['caf'] = 'centralafricanrepublic',
	['can'] = 'canada',
	['cck'] = 'cocos(keeling)islands',
	['che'] = 'switzerland',
	['chl'] = 'chile',
	['chn'] = 'china',
	['civ'] = "côted'ivoire",
	['cmr'] = 'cameroon',
	['cod'] = 'congo,democraticrepublicofthe',
	['cog'] = 'congo',
	['cok'] = 'cookislands',
	['col'] = 'colombia',
	['com'] = 'comoros',
	['cpv'] = 'caboverde',
	['cri'] = 'costarica',
	['cub'] = 'cuba',
	['cuw'] = 'curaçao',
	['cxr'] = 'christmasisland',
	['cym'] = 'caymanislands',
	['cyp'] = 'cyprus',
	['cze'] = 'czechia',
	['deu'] = 'germany',
	['dji'] = 'djibouti',
	['dma'] = 'dominica',
	['dnk'] = 'denmark',
	['dom'] = 'dominicanrepublic',
	['dza'] = 'algeria',
	['ecu'] = 'ecuador',
	['egy'] = 'egypt',
	['eri'] = 'eritrea',
	['esh'] = 'westernsahara',
	['esp'] = 'spain',
	['est'] = 'estonia',
	['eth'] = 'ethiopia',
	['fin'] = 'finland',
	['fji'] = 'fiji',
	['flk'] = 'falklandislands(malvinas)',
	['fra'] = 'france',
	['fro'] = 'faroeislands',
	['fsm'] = 'micronesia',
	['gab'] = 'gabon',
	['gbr'] = 'unitedkingdom',
	['geo'] = 'georgia',
	['ggy'] = 'guernsey',
	['gha'] = 'ghana',
	['gib'] = 'gibraltar',
	['gin'] = 'guinea',
	['glp'] = 'guadeloupe',
	['gmb'] = 'gambia',
	['gnb'] = 'guinea-bissau',
	['gnq'] = 'equatorialguinea',
	['grc'] = 'greece',
	['grd'] = 'grenada',
	['grl'] = 'greenland',
	['gtm'] = 'guatemala',
	['guf'] = 'frenchguiana',
	['gum'] = 'guam',
	['guy'] = 'guyana',
	['hkg'] = 'hongkong',
	['hmd'] = 'heardislandandmcdonaldislands',
	['hnd'] = 'honduras',
	['hrv'] = 'croatia',
	['hti'] = 'haiti',
	['hun'] = 'hungary',
	['idn'] = 'indonesia',
	['imn'] = 'isleofman',
	['ind'] = 'india',
	['iot'] = 'britishindianoceanterritory',
	['irl'] = 'ireland',
	['irn'] = 'iran',
	['irq'] = 'iraq',
	['isl'] = 'iceland',
	['isr'] = 'israel',
	['ita'] = 'italy',
	['jam'] = 'jamaica',
	['jey'] = 'jersey',
	['jor'] = 'jordan',
	['jpn'] = 'japan',
	['kaz'] = 'kazakhstan',
	['ken'] = 'kenya',
	['kgz'] = 'kyrgyzstan',
	['khm'] = 'cambodia',
	['kir'] = 'kiribati',
	['kna'] = 'saintkittsandnevis',
	['kor'] = 'southkorea',
	['kwt'] = 'kuwait',
	['lao'] = 'laos',
	['lbn'] = 'lebanon',
	['lbr'] = 'liberia',
	['lby'] = 'libya',
	['lca'] = 'saintlucia',
	['lie'] = 'liechtenstein',
	['lka'] = 'srilanka',
	['lso'] = 'lesotho',
	['ltu'] = 'lithuania',
	['lux'] = 'luxembourg',
	['lva'] = 'latvia',
	['mac'] = 'macau',
	['maf'] = 'saintmartin(frenchpart)',
	['mar'] = 'morocco',
	['mco'] = 'monaco',
	['mda'] = 'moldova',
	['mdg'] = 'madagascar',
	['mdv'] = 'maldives',
	['mex'] = 'mexico',
	['mhl'] = 'marshallislands',
	['mkd'] = 'northmacedonia',
	['mli'] = 'mali',
	['mlt'] = 'malta',
	['mmr'] = 'myanmar',
	['mne'] = 'montenegro',
	['mng'] = 'mongolia',
	['mnp'] = 'northernmarianaislands',
	['moz'] = 'mozambique',
	['mrt'] = 'mauritania',
	['msr'] = 'montserrat',
	['mtq'] = 'martinique',
	['mus'] = 'mauritius',
	['mwi'] = 'malawi',
	['mys'] = 'malaysia',
	['myt'] = 'mayotte',
	['nam'] = 'namibia',
	['ncl'] = 'newcaledonia',
	['ner'] = 'niger',
	['nfk'] = 'norfolkisland',
	['nga'] = 'nigeria',
	['nic'] = 'nicaragua',
	['niu'] = 'niue',
	['nld'] = 'netherlands',
	['nor'] = 'norway',
	['npl'] = 'nepal',
	['nru'] = 'nauru',
	['nzl'] = 'newzealand',
	['omn'] = 'oman',
	['pak'] = 'pakistan',
	['pan'] = 'panama',
	['pcn'] = 'pitcairn',
	['per'] = 'peru',
	['phl'] = 'philippines',
	['plw'] = 'palau',
	['png'] = 'papuanewguinea',
	['pol'] = 'poland',
	['pri'] = 'puertorico',
	['prk'] = 'northkorea',
	['prt'] = 'portugal',
	['pry'] = 'paraguay',
	['pse'] = 'palestine',
	['pyf'] = 'frenchpolynesia',
	['qat'] = 'qatar',
	['reu'] = 'réunion',
	['rou'] = 'romania',
	['rus'] = 'russia',
	['rwa'] = 'rwanda',
	['sau'] = 'saudiarabia',
	['sdn'] = 'sudan',
	['sen'] = 'senegal',
	['sgp'] = 'singapore',
	['sgs'] = 'southgeorgiaandthesouthsandwichislands',
	['shn'] = 'sainthelena',
	['sjm'] = 'svalbardandjanmayen',
	['slb'] = 'solomonislands',
	['sle'] = 'sierraleone',
	['slv'] = 'elsalvador',
	['smr'] = 'sanmarino',
	['som'] = 'somalia',
	['spm'] = 'saintpierreandmiquelon',
	['srb'] = 'serbia',
	['ssd'] = 'southsudan',
	['stp'] = 'saotomeandprincipe',
	['sur'] = 'suriname',
	['svk'] = 'slovakia',
	['svn'] = 'slovenia',
	['swe'] = 'sweden',
	['swz'] = 'eswatini',
	['sxm'] = 'sintmaarten(dutchpart)',
	['syc'] = 'seychelles',
	['syr'] = 'syria',
	['tca'] = 'turksandcaicosislands',
	['tcd'] = 'chad',
	['tgo'] = 'togo',
	['tha'] = 'thailand',
	['tjk'] = 'tajikistan',
	['tkl'] = 'tokelau',
	['tkm'] = 'turkmenistan',
	['tls'] = 'timor-leste',
	['ton'] = 'tonga',
	['tto'] = 'trinidadandtobago',
	['tun'] = 'tunisia',
	['tur'] = 'turkey',
	['tuv'] = 'tuvalu',
	['twn'] = 'taiwan',
	['tza'] = 'tanzania',
	['uga'] = 'uganda',
	['ukr'] = 'ukraine',
	['umi'] = 'unitedstatesminoroutlyingislands',
	['ury'] = 'uruguay',
	['usa'] = 'unitedstates',
	['uzb'] = 'uzbekistan',
	['vat'] = 'vaticancity',
	['vct'] = 'saintvincentandthegrenadines',
	['ven'] = 'venezuela(bolivarianrepublicof)',
	['vgb'] = 'virginislands(british)',
	['vir'] = 'virginislands(u.s.)',
	['vnm'] = 'vietnam',
	['vut'] = 'vanuatu',
	['wlf'] = 'wallisandfutuna',
	['wsm'] = 'samoa',
	['yem'] = 'yemen',
	['zaf'] = 'southafrica',
	['zmb'] = 'zambia',
	['zwe'] = 'zimbabwe',

	-- ISO 3166-2:GB
	['eng'] = 'england',
	['nir'] = 'northernireland',
	['sct'] = 'scotland',
	['wls'] = 'wales',

	-- Other
	['anz'] = 'oceania',
	['cis'] = 'commonwealthofindependentstates',
	['int'] = 'world',
	['sam'] = 'southamerica',
	['sca'] = 'scandinavia',
	['sea'] = 'southeastasia',
	['uae'] = 'unitedarabemirates',

	['tbd'] = 'filler',
}

-- This table includes:
--   ISO 3166-3
--   Accents/special characters
--   Other
local aliases = {
	-- ISO 3166-3
	['suhh'] = 'ussr',
	['yucs'] = 'yugoslavia',

	-- Accents/special characters
	['aland'] = 'ålandislands',
	['Ålandislands'] = 'ålandislands',
	['curacao'] = 'curaçao',
	['ivorycoast'] = "côted'ivoire",

	-- Other
	['bonaire'] = 'bonaire,sinteustatiusandsaba',
	['sinteustatius'] = 'bonaire,sinteustatiusandsaba',
	['saba'] = 'bonaire,sinteustatiusandsaba',
	['caribbeannetherlands'] = 'bonaire,sinteustatiusandsaba',
	['bosnia'] = 'bosniaandherzegovina',
	['bosnia&herzegovina'] = 'bosniaandherzegovina',
	['bruneidarussalam'] = 'brunei',
	['democraticrepublicofthecongo'] = 'congo,democraticrepublicofthe',
	['cocosislands'] = 'cocos(keeling)islands',
	['keelingislands'] = 'cocos(keeling)islands',
	['czech'] = 'czechia',
	['czechrepublic'] = 'czechia',
	['europe'] = 'europeanunion',
	['holland'] = 'netherlands',
	['international'] = 'world',
	['korea'] = 'southkorea',
	['macao'] = 'macau',
	['nord'] = 'nordiccountries',
	['nordic'] = 'nordiccountries',
	['nordiccouncil'] = 'nordiccountries',
	['macedonia'] = 'northmacedonia',
	['makedonia'] = 'northmacedonia',
	['micronesia'] = 'federatedstatesofmicronesia',
	['republic of macedonia'] = 'northmacedonia',
	['scandinavia'] = 'nordiccountries',
	['saintmartin'] = 'saintmartin(frenchpart)',
	['sintmaarten'] = 'sintmaarten(dutchpart)',
	['slovakrepublic'] = 'slovakia',
	['chinesetaipei'] = 'taiwan',
	['tristan'] = 'tristandacunha',
	['usca'] = 'northamerica',
	['unasur'] = 'southamerica',
	['unitedstatesofamerica'] = 'unitedstates',
	['holysee'] = 'vaticancity',
	['vatican'] = 'vaticancity',
	['virginislands'] = 'virginislands(british)',
	['britishvirginislands'] = 'virginislands(british)',
	['u.s.virginislands'] = 'virginislands(u.s.)',
	['unitedstatesvirginislands'] = 'virginislands(u.s.)',
	['u.s.minoroutlyingislands'] = 'unitedstatesminoroutlyingislands',
	['global'] = 'world',
	--needed due to lpdb length restrictions
	--for inside matches --> max length 20
	--minus the spaces in cut of the flag names
	['southgeorgiaandth'] = 'southgeorgiaandthesouthsandwichislands',
	['bosniaandherzegovi'] = 'bosniaandherzegovina',
	--for inside player --> max length 40
	--minus the spaces in cut of the flag names
	['southgeorgiaandthesouthsandwichisl'] = 'southgeorgiaandthesouthsandwichislands',

	--language flag abbreviations
	['usuk'] = 'englishspeaking',
	['deat'] = 'germanspeaking',
	['esmx'] = 'spanishspeaking',
	['ptbr'] = 'portuguesespeaking',
	['ruby'] = 'russianspeaking',

	--language flag aliases
	['engspeaking'] = 'englishspeaking',
	['gerspeaking'] = 'germanspeaking',

	['ff'] = 'filler',
	['fillerflag'] = 'filler',
	['unknown'] = 'filler',

	['nonrepresenting'] = 'non-representing',
	['non'] = 'non-representing',
	['none'] = 'non-representing',
}

-- This table includes
-- ISO 639-1 (language iso) values
-- for languages that have a special flag
local languageTwoLetter = {
	--language flag abbreviations
	['en'] = 'englishspeaking',
	['de'] = 'germanspeaking',
	['es'] = 'spanishspeaking',
	['pt'] = 'portuguesespeaking',
	['ru'] = 'russianspeaking',
}

-- This table includes
-- ISO 639-2/T (language iso) values
-- for languages that have a special flag
local languageThreeLetter = {
	--language flag abbreviations
	['eng'] = 'englishspeaking',
	['deu'] = 'germanspeaking',
	['spa'] = 'spanishspeaking',
	['por'] = 'portuguesespeaking',
	['rus'] = 'russianspeaking',
}

-- This table includes
-- ISO 3166-2 to the ISO 3166-1 country, that fulfill
-- https://liquipedia.net/commons/Liquipedia:Flag_and_Country_Policy#Countries
local iso31662 = {
	['wales'] = 'unitedkingdom',
	['scotland'] = 'unitedkingdom',
	['england'] = 'unitedkingdom',
	['northernireland'] = 'unitedkingdom',
}

return {
	data = data,
	twoLetter = twoLetter,
	threeLetter = threeLetter,
	aliases = aliases,
	languageTwoLetter = languageTwoLetter,
	languageThreeLetter = languageThreeLetter,
	iso31662 = iso31662,
}
