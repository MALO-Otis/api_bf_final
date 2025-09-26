// Données géographiques complètes du Burkina Faso
// Structure hiérarchique avec système de codification : régions, provinces, communes, villages
// Toutes les régions incluses et classées par ordre alphabétique

class GeographieData {
  /// Liste complète des régions du Burkina Faso (classées par ordre alphabétique)
  static const List<Map<String, dynamic>> regionsBurkina = [
    {'code': '01', 'nom': 'BOUCLE DU MOUHOUN'},
    {'code': '02', 'nom': 'CASCADES'},
    {'code': '03', 'nom': 'CENTRE'},
    {'code': '04', 'nom': 'CENTRE-EST'},
    {'code': '05', 'nom': 'CENTRE-NORD'},
    {'code': '06', 'nom': 'CENTRE-OUEST'},
    {'code': '07', 'nom': 'CENTRE-SUD'},
    {'code': '08', 'nom': 'EST'},
    {'code': '09', 'nom': 'HAUTS-BASSINS'},
    {'code': '10', 'nom': 'NORD'},
    {'code': '11', 'nom': 'PLATEAU-CENTRAL'},
    {'code': '12', 'nom': 'SAHEL'},
    {'code': '13', 'nom': 'SUD-OUEST'},
  ];

  /// Provinces par région (codifiées et classées alphabétiquement)
  static const Map<String, List<Map<String, dynamic>>> provincesParRegion = {
    '01': [
      // BOUCLE DU MOUHOUN (classées alphabétiquement)
      {'code': '01', 'nom': 'BALE'},
      {'code': '02', 'nom': 'BANWA'},
      {'code': '03', 'nom': 'KOSSI'},
      {'code': '04', 'nom': 'MOUHOUN'},
      {'code': '05', 'nom': 'NAYALA'},
      {'code': '06', 'nom': 'SOUROU'},
    ],
    '02': [
      // CASCADES (classées alphabétiquement)
      {'code': '01', 'nom': 'COMOE'},
      {'code': '02', 'nom': 'LERABA'},
    ],
    '03': [
      // CENTRE
      {'code': '01', 'nom': 'KADIOGO'},
    ],
    '04': [
      // CENTRE-EST (classées alphabétiquement)
      {'code': '01', 'nom': 'BOULGOU'},
      {'code': '02', 'nom': 'KOULPELOGO'},
      {'code': '03', 'nom': 'KOURITENGA'},
    ],
    '05': [
      // CENTRE-NORD (classées alphabétiquement)
      {'code': '01', 'nom': 'BAM'},
      {'code': '02', 'nom': 'NAMENTENGA'},
      {'code': '03', 'nom': 'SANMATENGA'},
    ],
    '06': [
      // CENTRE-OUEST (classées alphabétiquement)
      {'code': '01', 'nom': 'BOULKIEMDE'},
      {'code': '02', 'nom': 'SANGUIE'},
      {'code': '03', 'nom': 'SISSILI'},
      {'code': '04', 'nom': 'ZIRO'},
    ],
    '07': [
      // CENTRE-SUD (classées alphabétiquement)
      {'code': '01', 'nom': 'BAZEGA'},
      {'code': '02', 'nom': 'NAHOURI'},
      {'code': '03', 'nom': 'ZOUNDWEOGO'},
    ],
    '08': [
      // EST (classées alphabétiquement)
      {'code': '01', 'nom': 'GNAGNA'},
      {'code': '02', 'nom': 'GOURMA'},
      {'code': '03', 'nom': 'KOMANDJOARI'},
      {'code': '04', 'nom': 'KOMPIENGA'},
      {'code': '05', 'nom': 'TAPOA'},
    ],
    '09': [
      // HAUTS-BASSINS (classées alphabétiquement)
      {'code': '01', 'nom': 'HOUET'},
      {'code': '02', 'nom': 'KENEDOUGOU'},
      {'code': '03', 'nom': 'TUY'},
    ],
    '10': [
      // NORD (classées alphabétiquement)
      {'code': '01', 'nom': 'LOROUM'},
      {'code': '02', 'nom': 'PASSORE'},
      {'code': '03', 'nom': 'YATENGA'},
      {'code': '04', 'nom': 'ZONDOMA'},
    ],
    '11': [
      // PLATEAU-CENTRAL (classées alphabétiquement)
      {'code': '01', 'nom': 'GANZOURGOU'},
      {'code': '02', 'nom': 'KOURWEOGO'},
      {'code': '03', 'nom': 'OUBRITENGA'},
    ],
    '12': [
      // SAHEL (classées alphabétiquement)
      {'code': '01', 'nom': 'OUDALAN'},
      {'code': '02', 'nom': 'SENO'},
      {'code': '03', 'nom': 'SOUM'},
      {'code': '04', 'nom': 'YAGHA'},
    ],
    '13': [
      // SUD-OUEST (classées alphabétiquement)
      {'code': '01', 'nom': 'BOUGOURIBA'},
      {'code': '02', 'nom': 'IOBA'},
      {'code': '03', 'nom': 'NOUMBIEL'},
      {'code': '04', 'nom': 'PONI'},
    ],
  };

  /// Communes par province (codifiées et classées alphabétiquement)
  /// Format : { 'codeRegion-codeProvince': [ {'code': '01', 'nom': 'Commune1'}, ... ] }
  static const Map<String, List<Map<String, dynamic>>> communesParProvince = {
    // BOUCLE DU MOUHOUN
    '01-01': [
      // BALE (classées alphabétiquement)
      {'code': '01', 'nom': 'BAGASSI'},
      {'code': '02', 'nom': 'BOROMO'},
      {'code': '03', 'nom': 'FARA'},
      {'code': '04', 'nom': 'OURY'},
      {'code': '05', 'nom': 'PA'},
      {'code': '06', 'nom': 'POMPOI'},
      {'code': '07', 'nom': 'POURA'},
      {'code': '08', 'nom': 'SIBY'},
      {'code': '10', 'nom': 'YAKO'},
      {'code': '11', 'nom': 'TCHERIBA'},
      //{'code': '12', 'nom': 'BISSANDEROU'},
      //{'code': '13', 'nom': 'DIDIE'},
      //{'code': '14', 'nom': 'SOROBOULI'},
      //{'code': '15', 'nom': 'SOUHO'},
    ],
    '01-02': [
      // BANWA (classées alphabétiquement)
      {'code': '01', 'nom': 'BALAVE'},
      {'code': '02', 'nom': 'KOUKA'},
      {'code': '03', 'nom': 'SAMI'},
      {'code': '04', 'nom': 'SANABA'},
      {'code': '05', 'nom': 'SOLENZO'},
      {'code': '06', 'nom': 'TANSILA'},
    ],
    '01-03': [
      // KOSSI (classées alphabétiquement)
      {'code': '01', 'nom': 'BARANI'},
      {'code': '02', 'nom': 'BOMBOROKUY'},
      {'code': '03', 'nom': 'BOURASSO'},
      {'code': '04', 'nom': 'DJIBASSO'},
      {'code': '05', 'nom': 'DOKUY'},
      {'code': '06', 'nom': 'DOUMBALA'},
      {'code': '07', 'nom': 'KOMBORI'},
      {'code': '08', 'nom': 'MADOUBA'},
      {'code': '09', 'nom': 'NOUNA'},
      {'code': '10', 'nom': 'SONO'},
    ],
    '01-04': [
      // MOUHOUN (classées alphabétiquement)
      {'code': '01', 'nom': 'BONDOKUY'},
      {'code': '02', 'nom': 'DEDOUGOU'},
      {'code': '03', 'nom': 'DOUROULA'},
      {'code': '04', 'nom': 'KONA'},
      {'code': '05', 'nom': 'OUARKOYE'},
      {'code': '06', 'nom': 'SAFANE'},
      {'code': '07', 'nom': 'TCHERIBA'},
    ],
    '01-05': [
      // NAYALA (classées alphabétiquement)
      {'code': '01', 'nom': 'GASSAN'},
      {'code': '02', 'nom': 'GOSSINA'},
      {'code': '03', 'nom': 'KOUGNY'},
      {'code': '04', 'nom': 'TOMA'},
      {'code': '05', 'nom': 'YABA'},
      {'code': '06', 'nom': 'YAKO'},
    ],
    '01-06': [
      // SOUROU (classées alphabétiquement)
      {'code': '01', 'nom': 'DI'},
      {'code': '02', 'nom': 'GOMBORO'},
      {'code': '03', 'nom': 'KASSOUM'},
      {'code': '04', 'nom': 'KIEMBARA'},
      {'code': '05', 'nom': 'LANFIERA'},
      {'code': '06', 'nom': 'LANKOUE'},
      {'code': '07', 'nom': 'TOENI'},
      {'code': '08', 'nom': 'TOUGAN'},
    ],

    // CASCADES
    '02-01': [
      // COMOE (classées alphabétiquement)
      {'code': '01', 'nom': 'BANFORA'},
      {'code': '02', 'nom': 'BEREGADOUGOU'},
      {'code': '03', 'nom': 'MANGODARA'},
      {'code': '04', 'nom': 'MOUSSODOUGOU'},
      {'code': '05', 'nom': 'NIANGOLOKO'},
      {'code': '06', 'nom': 'OUO'},
      {'code': '07', 'nom': 'SIDERADOUGOU'},
      {'code': '08', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '09', 'nom': 'TIEFORA'},
    ],
    '02-02': [
      // LERABA (classées alphabétiquement)
      {'code': '01', 'nom': 'DAKORO'},
      {'code': '02', 'nom': 'DOUNA'},
      {'code': '03', 'nom': 'KANKALABA'},
      {'code': '04', 'nom': 'LOUMANA'},
      {'code': '05', 'nom': 'NIANGOLOGO'},
      {'code': '06', 'nom': 'OUELENI'},
      {'code': '07', 'nom': 'SINDOU'},
      {'code': '08', 'nom': 'WOLONKOTO'},
    ],

    // CENTRE
    '03-01': [
      // KADIOGO (classées alphabétiquement)
      {'code': '01', 'nom': 'KOMKI-IPALA'},
      {'code': '02', 'nom': 'KOMSILGA'},
      {'code': '03', 'nom': 'KOUBRI'},
      {'code': '04', 'nom': 'OUAGADOUGOU'},
      {'code': '05', 'nom': 'PABRE'},
      {'code': '06', 'nom': 'SAABA'},
      {'code': '07', 'nom': 'TANGHIN-DASSOURI'},
    ],

    // CENTRE-EST
    '04-01': [
      // BOULGOU (classées alphabétiquement)
      {'code': '01', 'nom': 'BAGRE'},
      {'code': '02', 'nom': 'BANE'},
      {'code': '03', 'nom': 'BEGUEDO'},
      {'code': '04', 'nom': 'BISSIGA'},
      {'code': '05', 'nom': 'BITTOU'},
      {'code': '06', 'nom': 'BOUSSOUMA'},
      {'code': '07', 'nom': 'GARANGO'},
      {'code': '08', 'nom': 'KOMTOEGA'},
      {'code': '09', 'nom': 'NIAGHO'},
      {'code': '10', 'nom': 'TENKODOGO'},
      {'code': '11', 'nom': 'ZABRE'},
      {'code': '12', 'nom': 'ZOAGA'},
      {'code': '13', 'nom': 'ZONSE'},
    ],
    '04-02': [
      // KOULPELOGO (classées alphabétiquement)
      {'code': '01', 'nom': 'COMIN-YANGA'},
      {'code': '02', 'nom': 'LALGAYE'},
      {'code': '03', 'nom': 'OUARGAYE'},
      {'code': '04', 'nom': 'SANGHA'},
      {'code': '05', 'nom': 'SOUDOUGUI'},
      {'code': '06', 'nom': 'YARGATENGA'},
    ],
    '04-03': [
      // KOURITENGA (classées alphabétiquement)
      {'code': '01', 'nom': 'ANDEMTENGA'},
      {'code': '02', 'nom': 'BASKOURE'},
      {'code': '03', 'nom': 'DIALGAYE'},
      {'code': '04', 'nom': 'GOUNGHIN'},
      {'code': '05', 'nom': 'KANDO'},
      {'code': '06', 'nom': 'KOUPELA'},
      {'code': '07', 'nom': 'POUYTENGA'},
      {'code': '08', 'nom': 'TENSOBENTENGA'},
      {'code': '09', 'nom': 'YARGO'},
    ],

    // CENTRE-NORD
    '05-01': [
      // BAM (classées alphabétiquement)
      {'code': '01', 'nom': 'BOURZANGA'},
      {'code': '02', 'nom': 'GUIBARE'},
      {'code': '03', 'nom': 'KONGOUSSI'},
      {'code': '04', 'nom': 'NASSERE'},
      {'code': '05', 'nom': 'ROLLO'},
      {'code': '06', 'nom': 'ROUKO'},
      {'code': '07', 'nom': 'SABCE'},
      {'code': '08', 'nom': 'TIKARE'},
      {'code': '09', 'nom': 'ZIMTENGA'},
    ],
    '05-02': [
      // NAMENTENGA (classées alphabétiquement)
      {'code': '01', 'nom': 'BOALA'},
      {'code': '02', 'nom': 'BOULSA'},
      {'code': '03', 'nom': 'DARGO'},
      {'code': '04', 'nom': 'NAGBINGOU'},
      {'code': '05', 'nom': 'TOUGOURI'},
      {'code': '06', 'nom': 'YALGO'},
    ],
    '05-03': [
      // SANMATENGA (classées alphabétiquement)
      {'code': '01', 'nom': 'BARSALOGHO'},
      {'code': '02', 'nom': 'BOUSSOUMA'},
      {'code': '03', 'nom': 'DABLO'},
      {'code': '04', 'nom': 'KAYA'},
      {'code': '05', 'nom': 'KORSIMORO'},
      {'code': '06', 'nom': 'MANE'},
      {'code': '07', 'nom': 'NAMISSIGUIMA'},
      {'code': '08', 'nom': 'PENSA'},
      {'code': '09', 'nom': 'PIBAORE'},
      {'code': '10', 'nom': 'PISSILA'},
    ],

    // CENTRE-OUEST
    '06-01': [
      // BOULKIEMDE (classées alphabétiquement)
      {'code': '01', 'nom': 'BINGO'},
      {'code': '02', 'nom': 'IMASGO'},
      {'code': '03', 'nom': 'KINDI'},
      {'code': '04', 'nom': 'KOKOLOGO'},
      {'code': '05', 'nom': 'KOUDOUGOU'},
      {'code': '06', 'nom': 'NANORO'},
      {'code': '07', 'nom': 'NIANDIALA'},
      {'code': '08', 'nom': 'PELLA'},
      {'code': '09', 'nom': 'POA'},
      {'code': '10', 'nom': 'RAMONGO'},
      {'code': '11', 'nom': 'SABOU'},
      {'code': '12', 'nom': 'SIGLE'},
      {'code': '13', 'nom': 'SOAW'},
      {'code': '14', 'nom': 'SOURGOU'},
      {'code': '15', 'nom': 'THIOU'},
    ],
    '06-02': [
      // SANGUIE (classées alphabétiquement)
      {'code': '01', 'nom': 'DASSA'},
      {'code': '02', 'nom': 'DIDYR'},
      {'code': '03', 'nom': 'GODYR'},
      {'code': '04', 'nom': 'KORDIE'},
      {'code': '05', 'nom': 'POUNI'},
      {'code': '06', 'nom': 'REO'},
      {'code': '07', 'nom': 'TENADO'},
      {'code': '08', 'nom': 'ZAWARA'},
      {'code': '09', 'nom': 'GOUNDI'},
    ],
    '06-03': [
      // SISSILI (classées alphabétiquement)
      {'code': '01', 'nom': 'BIEHA'},
      {'code': '02', 'nom': 'BOURA'},
      {'code': '03', 'nom': 'LEO'},
      {'code': '04', 'nom': 'NEBIELIANAYOU'},
      {'code': '05', 'nom': 'SILLY'},
      {'code': '06', 'nom': 'TO'},
    ],
    '06-04': [
      // ZIRO (classées alphabétiquement)
      {'code': '01', 'nom': 'BAKATA'},
      {'code': '02', 'nom': 'BOUGNOUNOU'},
      {'code': '03', 'nom': 'CASSOU'},
      {'code': '04', 'nom': 'GAO'},
      {'code': '05', 'nom': 'SAPOUY'},
    ],

    // CENTRE-SUD
    '07-01': [
      // BAZEGA (classées alphabétiquement)
      {'code': '01', 'nom': 'DOULOUGOU'},
      {'code': '02', 'nom': 'GAONGO'},
      {'code': '03', 'nom': 'IPELCE'},
      {'code': '04', 'nom': 'KAYAO'},
      {'code': '05', 'nom': 'KOMBISSIRI'},
      {'code': '06', 'nom': 'SAPONE'},
      {'code': '07', 'nom': 'TOECE'},
    ],
    '07-02': [
      // NAHOURI (classées alphabétiquement)
      {'code': '01', 'nom': 'GUIARO'},
      {'code': '02', 'nom': 'PO'},
      {'code': '03', 'nom': 'TIEBELE'},
      {'code': '04', 'nom': 'ZIOU'},
    ],
    '07-03': [
      // ZOUNDWEOGO (classées alphabétiquement)
      {'code': '01', 'nom': 'BINDE'},
      {'code': '02', 'nom': 'GOGO'},
      {'code': '03', 'nom': 'GOMBOUSSOUGOU'},
      {'code': '04', 'nom': 'GUIBA'},
      {'code': '05', 'nom': 'MANGA'},
      {'code': '06', 'nom': 'NOBERE'},
    ],

    // EST
    '08-01': [
      // GNAGNA (classées alphabétiquement)
      {'code': '01', 'nom': 'BILANGA'},
      {'code': '02', 'nom': 'BOGANDE'},
      {'code': '03', 'nom': 'COALLA'},
      {'code': '04', 'nom': 'LIPTOUGOU'},
      {'code': '05', 'nom': 'MANNI'},
      {'code': '06', 'nom': 'PIELA'},
      {'code': '07', 'nom': 'THION'},
    ],
    '08-02': [
      // GOURMA (classées alphabétiquement)
      {'code': '01', 'nom': 'DIABO'},
      {'code': '02', 'nom': 'DIAPANGOU'},
      {'code': '03', 'nom': 'FADA N\'GOURMA'},
      {'code': '04', 'nom': 'MATIACOALI'},
      {'code': '05', 'nom': 'TIBGA'},
      {'code': '06', 'nom': 'YAMBA'},
    ],
    '08-03': [
      // KOMONDJARI (classées alphabétiquement)
      {'code': '01', 'nom': 'BARTIEBOUGOU'},
      {'code': '02', 'nom': 'FOUTOURI'},
      {'code': '03', 'nom': 'GAYERI'},
    ],
    '08-04': [
      // KOMPIENGA (classées alphabétiquement)
      {'code': '01', 'nom': 'KOMPIENGA'},
      {'code': '02', 'nom': 'MADJOARI'},
      {'code': '03', 'nom': 'PAMA'},
    ],
    '08-05': [
      // TAPOA (classées alphabétiquement)
      {'code': '01', 'nom': 'BOTOU'},
      {'code': '02', 'nom': 'DIAPAGA'},
      {'code': '03', 'nom': 'KANTCHARI'},
      {'code': '04', 'nom': 'LOGOBOU'},
      {'code': '05', 'nom': 'NAMOUNOU'},
      {'code': '06', 'nom': 'PARTIAGA'},
      {'code': '07', 'nom': 'TAMBAGA'},
      {'code': '08', 'nom': 'TANSARGA'},
    ],

    // HAUTS-BASSINS
    '09-01': [
      // HOUET (classées alphabétiquement)
      {'code': '01', 'nom': 'BAMA'},
      {'code': '02', 'nom': 'BOBO-DIOULASSO'},
      {'code': '03', 'nom': 'DANDE'},
      {'code': '04', 'nom': 'FARAMANA'},
      {'code': '05', 'nom': 'KARANGASSO-VIGUE'},
      {'code': '06', 'nom': 'KOUNDOUGOU'},
      {'code': '07', 'nom': 'LENA'},
      {'code': '08', 'nom': 'PADEMA'},
      {'code': '09', 'nom': 'PENI'},
      {'code': '10', 'nom': 'SATIRI'},
      {'code': '11', 'nom': 'TOUSSIANA'},
      {'code': '12', 'nom': 'BADARA'},
    ],
    '09-02': [
      // KENEDOUGOU (classées alphabétiquement)
      {'code': '01', 'nom': 'DJIGOUERA'},
      {'code': '02', 'nom': 'KANGALA'},
      {'code': '03', 'nom': 'KOLOKO'},
      {'code': '04', 'nom': 'KOURINION'},
      {'code': '05', 'nom': 'DOROLA'},
      {'code': '06', 'nom': 'ORODARA'},
      {'code': '07', 'nom': 'SAMOGHOHIRI'},
      {'code': '08', 'nom': 'SAMOGOHIRI'},
      {'code': '09', 'nom': 'SINDOU'},
    ],
    '09-03': [
      // TUY (classées alphabétiquement - ajout SALA d'après l'image)
      {'code': '01', 'nom': 'BEKUY'},
      {'code': '02', 'nom': 'BEREBA'},
      {'code': '03', 'nom': 'BONI'},
      {'code': '04', 'nom': 'HOUNDE'},
      {'code': '05', 'nom': 'KOUMBIA'},
      {'code': '06', 'nom': 'SALA'},
    ],

    // NORD
    '10-01': [
      // LOROUM (classées alphabétiquement)
      {'code': '01', 'nom': 'BANH'},
      {'code': '02', 'nom': 'OUINDIGUI'},
      {'code': '03', 'nom': 'SOLLE'},
      {'code': '04', 'nom': 'TITAO'},
    ],
    '10-02': [
      // PASSORE (classées alphabétiquement)
      {'code': '01', 'nom': 'ARBOLLE'},
      {'code': '02', 'nom': 'BAGRE'},
      {'code': '03', 'nom': 'BOKIN'},
      {'code': '04', 'nom': 'GOMPONSOM'},
      {'code': '05', 'nom': 'KIRSI'},
      {'code': '06', 'nom': 'LA-TODEN'},
      {'code': '07', 'nom': 'PILIMPIKOU'},
      {'code': '08', 'nom': 'SAMBA'},
      {'code': '09', 'nom': 'YAKO'},
    ],
    '10-03': [
      // YATENGA (classées alphabétiquement)
      {'code': '01', 'nom': 'BARGA'},
      {'code': '02', 'nom': 'KAIN'},
      {'code': '03', 'nom': 'KALSAKA'},
      {'code': '04', 'nom': 'KOUMBRI'},
      {'code': '05', 'nom': 'NAMISSIGUIMA'},
      {'code': '06', 'nom': 'OUAHIGOUYA'},
      {'code': '07', 'nom': 'OULA'},
      {'code': '08', 'nom': 'RAMBO'},
      {'code': '09', 'nom': 'SEGUENEGAS'},
      {'code': '10', 'nom': 'SOUM'},
      {'code': '11', 'nom': 'TANGAYE'},
      {'code': '12', 'nom': 'THIOU'},
      {'code': '13', 'nom': 'ZOGORE'},
    ],
    '10-04': [
      // ZONDOMA (classées alphabétiquement)
      {'code': '01', 'nom': 'BASSI'},
      {'code': '02', 'nom': 'BOUSSOU'},
      {'code': '03', 'nom': 'GOURCY'},
      {'code': '04', 'nom': 'LEBA'},
      {'code': '05', 'nom': 'TOUGO'},
    ],

    // PLATEAU-CENTRAL
    '11-01': [
      // GANZOURGOU (classées alphabétiquement)
      {'code': '01', 'nom': 'BOUDRY'},
      {'code': '02', 'nom': 'KOGHO'},
      {'code': '03', 'nom': 'MEGUET'},
      {'code': '04', 'nom': 'MOGTEDO'},
      {'code': '05', 'nom': 'SALOGO'},
      {'code': '06', 'nom': 'ZAM'},
      {'code': '07', 'nom': 'ZOUNGOU'},
      {'code': '08', 'nom': 'ZORGHO'},
    ],
    '11-02': [
      // KOURWEOGO (classées alphabétiquement)
      {'code': '01', 'nom': 'BOUSSE'},
      {'code': '02', 'nom': 'LAYE'},
      {'code': '03', 'nom': 'NIOU'},
      {'code': '04', 'nom': 'SOURGOUBILA'},
    ],
    '11-03': [
      // OUBRITENGA (classées alphabétiquement)
      {'code': '01', 'nom': 'ABSOUYA'},
      {'code': '02', 'nom': 'DAPELOGO'},
      {'code': '03', 'nom': 'LOUMBILA'},
      {'code': '04', 'nom': 'NAGREONGO'},
      {'code': '05', 'nom': 'OURGOU-MANEGA'},
      {'code': '06', 'nom': 'ZINIARE'},
      {'code': '07', 'nom': 'ZITENGA'},
    ],

    // SAHEL
    '12-01': [
      // OUDALAN (classées alphabétiquement)
      {'code': '01', 'nom': 'DEOU'},
      {'code': '02', 'nom': 'GOROM-GOROM'},
      {'code': '03', 'nom': 'MARKOYE'},
      {'code': '04', 'nom': 'OURSI'},
      {'code': '05', 'nom': 'TIN-AKOFF'},
    ],
    '12-02': [
      // SENO (classées alphabétiquement)
      {'code': '01', 'nom': 'BANI'},
      {'code': '02', 'nom': 'DORI'},
      {'code': '03', 'nom': 'FALAGOUNTOU'},
      {'code': '04', 'nom': 'GORGADJI'},
      {'code': '05', 'nom': 'SAMPELGA'},
      {'code': '06', 'nom': 'SEYTENGA'},
    ],
    '12-03': [
      // SOUM (classées alphabétiquement)
      {'code': '01', 'nom': 'ARBINDA'},
      {'code': '02', 'nom': 'BARABOULE'},
      {'code': '03', 'nom': 'DJIBO'},
      {'code': '04', 'nom': 'KELBO'},
      {'code': '05', 'nom': 'KOUTOUGOU'},
      {'code': '06', 'nom': 'NASSOUMBOU'},
      {'code': '07', 'nom': 'POBE-MENGAO'},
      {'code': '08', 'nom': 'TONGOMAYEL'},
    ],
    '12-04': [
      // YAGHA (classées alphabétiquement)
      {'code': '01', 'nom': 'BOUNDORE'},
      {'code': '02', 'nom': 'MANSILA'},
      {'code': '03', 'nom': 'SEBBA'},
      {'code': '04', 'nom': 'SOLHAN'},
      {'code': '05', 'nom': 'TANKOUGOUNADIE'},
    ],

    // SUD-OUEST
    '13-01': [
      // BOUGOURIBA (classées alphabétiquement)
      {'code': '01', 'nom': 'BATIE'},
      {'code': '02', 'nom': 'BOUSSERA'},
      {'code': '03', 'nom': 'DIEBOUGOU'},
      {'code': '04', 'nom': 'DJIGOUE'},
      {'code': '05', 'nom': 'IOLONIORO'},
      {'code': '06', 'nom': 'LEGMOIN'},
      {'code': '07', 'nom': 'NAKO'},
      {'code': '08', 'nom': 'TIANKOURA'},
    ],
    '13-02': [
      // IOBA (classées alphabétiquement)
      {'code': '01', 'nom': 'DANO'},
      {'code': '02', 'nom': 'DISSIN'},
      {'code': '03', 'nom': 'GUEGUERE'},
      {'code': '04', 'nom': 'KOPER'},
      {'code': '05', 'nom': 'ORONKUA'},
      {'code': '06', 'nom': 'ZAMBO'},
    ],
    '13-03': [
      // NOUMBIEL (classées alphabétiquement)
      {'code': '01', 'nom': 'BATONDO'},
      {'code': '02', 'nom': 'LEGMOIN'},
      {'code': '03', 'nom': 'MIDEBDO'},
      {'code': '04', 'nom': 'TOUMOUSSENI'},
    ],
    '13-04': [
      // PONI (classées alphabétiquement)
      {'code': '01', 'nom': 'BOUROUM-BOUROUM'},
      {'code': '02', 'nom': 'DJIGOUE'},
      {'code': '03', 'nom': 'GAOUA'},
      {'code': '04', 'nom': 'GBOMBLORA'},
      {'code': '05', 'nom': 'KAMPTI'},
      {'code': '06', 'nom': 'LOROPENI'},
      {'code': '07', 'nom': 'MALBA'},
      {'code': '08', 'nom': 'NAKO'},
      {'code': '09', 'nom': 'PERIGBAN'},
    ],
  };

  /// Villages par commune (données complètes avec codification)
  /// Format : { 'codeRegion-codeProvince-codeCommune': [ {'code': '01', 'nom': 'Village1'}, ... ] }
  static const Map<String, List<Map<String, dynamic>>> villagesParCommune = {
    // CASCADES - LERABA
    '02-02-03': [
      // CASCADES > LERABA > KANKALABA (classés alphabétiquement)
      {'code': '01', 'nom': 'BOUGOULA'},
      {'code': '02', 'nom': 'DIONSO'},
      {'code': '03', 'nom': 'KANKALABA'},
      {'code': '04', 'nom': 'KOLASSO'},
      {'code': '05', 'nom': 'NIANTONO'},
    ],
    '02-02-04': [
      // CASCADES > LERABA > LOUMANA (classés alphabétiquement)
      {'code': '01', 'nom': 'BAGUERA'},
      {'code': '02', 'nom': 'KANGOURA'},
      {'code': '03', 'nom': 'LOUMANA'},
      {'code': '04', 'nom': 'NIANSOGONI'},
      {'code': '05', 'nom': 'SOUMADOUGOUDJAN'},
      {'code': '06', 'nom': 'TCHONGO'},
    ],

    // CASCADES - COMOE
    '02-01-03': [
      // CASCADES > COMOE > MANGODARA (classés alphabétiquement selon l'image)
      {'code': '01', 'nom': 'BAKARIDJAN'},
      {'code': '02', 'nom': 'BANAKORO'},
      {'code': '03', 'nom': 'BANAKELESSO'},
      {'code': '04', 'nom': 'DANDOUGOU'},
      {'code': '05', 'nom': 'DIARRAKOROSSO'},
      {'code': '06', 'nom': 'FARAKORO'},
      {'code': '07', 'nom': 'GAMBI'},
      {'code': '08', 'nom': 'GNAMINADOUGOU'},
      {'code': '09', 'nom': 'GONKODJAN'},
      {'code': '10', 'nom': 'KANDO'},
      {'code': '11', 'nom': 'KORGO'},
      {'code': '12', 'nom': 'LARABIN'},
      {'code': '13', 'nom': 'MANGODARA'},
      {'code': '14', 'nom': 'SIRAKORO'},
      {'code': '15', 'nom': 'SOKOURA'},
      {'code': '16', 'nom': 'TOMIKOROSSO'},
      {'code': '17', 'nom': 'TORANDOUGOU'},
      {'code': '18', 'nom': 'TORGO'},
      {'code': '19', 'nom': 'TOROKORO'},
    ],
    '02-01-08': [
      // CASCADES > COMOE > SOUBAKANIEDOUGOU (classés alphabétiquement)
      {'code': '01', 'nom': 'SOUBAKANIEDOUGOU'},
    ],

    // HAUTS-BASSINS - HOUET
    '09-01-11': [
      // HAUTS-BASSINS > HOUET > TOUSSIANA (classés alphabétiquement)
      {'code': '01', 'nom': 'TAPOKO'},
      {'code': '02', 'nom': 'TOUSSIANA'},
    ],
    '09-01-10': [
      // HAUTS-BASSINS > HOUET > SATIRI (classés alphabétiquement)
      {'code': '01', 'nom': 'KOROMA'},
      {'code': '02', 'nom': 'SALA'},
      {'code': '03', 'nom': 'SATIRI'},
    ],

    // HAUTS-BASSINS - TUY
    '09-03-02': [
      // HAUTS-BASSINS > TUY > BEREBA (classés alphabétiquement)
      {'code': '01', 'nom': 'MARO'},
    ],

    // CENTRE-OUEST - BOULKIEMDE
    '06-01-05': [
      // CENTRE-OUEST > BOULKIEMDE > KOUDOUGOU (classés alphabétiquement)
      {'code': '01', 'nom': 'KANKALBILA'},
      {'code': '02', 'nom': 'RAMONGO'},
      {'code': '03', 'nom': 'SALLA'},
      {'code': '04', 'nom': 'SIGOGHIN'},
      {'code': '05', 'nom': 'TIOGO MOSSI'},
    ],

    // CENTRE-SUD - NAHOURI

    // CENTRE-EST - BOULGOU
    '04-01-01': [
      // CENTRE-EST > BOULGOU > BAGRE (classés alphabétiquement selon l'image)
      {'code': '01', 'nom': 'BAGRE'},
    ],

    // CENTRE-SUD - NAHOURI
    '07-02-02': [
      // CENTRE-SUD > NAHOURI > PO (classés alphabétiquement)
      {'code': '01', 'nom': 'BOUROU'},
      {'code': '02', 'nom': 'TIAKANE'},
      {'code': '03', 'nom': 'YARO'},
    ],

    '07-02-0"': [
      // CENTRE-SUD > NAHOURI > GUIARO (classés alphabétiquement)
      {'code': '01', 'nom': 'KOLLO'},
      {'code': '02', 'nom': 'OUALEM'},
      {'code': '03', 'nom': 'SARO'},
    ],

    // BOUCLE DU MOUHOUN - BALE
    '01-01-08': [
      // BOUCLE DU MOUHOUN > BALE > SIBY (classés alphabétiquement)
      {'code': '01', 'nom': 'BALLAO'},
      {'code': '02', 'nom': 'DIDIE'},
      {'code': '03', 'nom': 'SIBY'},
      {'code': '04', 'nom': 'SOROBOULY'},
      {'code': '05', 'nom': 'SOUHO'},
    ],
    '01-01-05': [
      // BOUCLE DU MOUHOUN > BALE > PA (classés alphabétiquement)
      {'code': '01', 'nom': 'DIDIE'},
      {'code': '02', 'nom': 'PA'},
    ],

    // BOUCLE DU MOUHOUN - MOUHOUN
    '01-04-02': [
      // BOUCLE DU MOUHOUN > MOUHOUN > DEDOUGOU (classés alphabétiquement)
      {'code': '01', 'nom': 'DEDOUGOU'},
      {'code': '02', 'nom': 'KARI'},
    ],
    '01-04-03': [
      // BOUCLE DU MOUHOUN > MOUHOUN > DOUROULA (classés alphabétiquement)
      {'code': '01', 'nom': 'BLADI'},
      {'code': '02', 'nom': 'DOUROULA'},
      {'code': '03', 'nom': 'KANCONO'},
      {'code': '04', 'nom': 'KASSACONGO'},
      {'code': '05', 'nom': 'KIRICONGO'},
      {'code': '06', 'nom': 'KOUSSIRI'},
      {'code': '07', 'nom': 'NOROGTENGA'},
    ],
    '01-04-07': [
      // BOUCLE DU MOUHOUN > MOUHOUN > TCHERIBA (classés alphabétiquement)
      {'code': '01', 'nom': 'BANOUBA'},
      {'code': '02', 'nom': 'BEKEYOU'},
      {'code': '03', 'nom': 'BISSANDEROU'},
      {'code': '04', 'nom': 'ETOUAYOU'},
      {'code': '05', 'nom': 'GAMADOUGOU'},
      {'code': '06', 'nom': 'OUALOU'},
      {'code': '07', 'nom': 'OUEZALA'},
      {'code': '08', 'nom': 'TCHERIBA'},
      {'code': '09', 'nom': 'TIERKOU'},
      {'code': '10', 'nom': 'TIKAN'},
      {'code': '11', 'nom': 'YOULOU'},
    ],

    // CENTRE-OUEST - SANGUIE
    '06-02-01': [
      // CENTRE-OUEST > SANGUIE > DASSA (classés alphabétiquement)
      {'code': '01', 'nom': 'DASSA'},
    ],
    '06-02-06': [
      // CENTRE-OUEST > SANGUIE > REO (classés alphabétiquement)
      {'code': '01', 'nom': 'PERKOAN'},
      {'code': '02', 'nom': 'REO'},
    ],
    '06-02-07': [
      // CENTRE-OUEST > SANGUIE > TENADO (classés alphabétiquement)
      {'code': '01', 'nom': 'TENADO'},
      {'code': '02', 'nom': 'TIALGO'},
      {'code': '03', 'nom': 'TIOGO'},
    ],
    '06-02-08': [
      // CENTRE-OUEST > SANGUIE > ZAWARA (classés alphabétiquement)
      {'code': '01', 'nom': 'GOUNDI'},
    ],

    // CENTRE-OUEST - SISSILI
    '06-03-06': [
      // CENTRE-OUEST > SISSILI > TO (classés alphabétiquement)
      {'code': '01', 'nom': 'TO'},
    ],

    // CENTRE-OUEST - BOULKIEMDE (autres communes)
    '06-01-02': [
      // CENTRE-OUEST > BOULKIEMDE > IMASGO (classés alphabétiquement)
      {'code': '01', 'nom': 'OUERA'},
    ],
    '06-01-11': [
      // CENTRE-OUEST > BOULKIEMDE > SABOU (classés alphabétiquement)
      {'code': '01', 'nom': 'NADIOLO'},
    ],
    '06-01-14': [
      // CENTRE-OUEST > BOULKIEMDE > SOURGOU (classés alphabétiquement)
      {'code': '01', 'nom': 'SOURGOU'},
    ],
    '06-01-08': [
      // CENTRE-OUEST > BOULKIEMDE > PELLA (classés alphabétiquement)
      {'code': '01', 'nom': 'PELLA'},
    ],
    '06-01-09': [
      // CENTRE-OUEST > BOULKIEMDE > POA (classés alphabétiquement)
      {'code': '01', 'nom': 'POA'},
    ],
    '06-01-13': [
      // CENTRE-OUEST > BOULKIEMDE > SOAW (classés alphabétiquement)
      {'code': '01', 'nom': 'SOAW'},
    ],
    '06-01-04': [
      // CENTRE-OUEST > BOULKIEMDE > KOKOLOGO (classés alphabétiquement)
      {'code': '01', 'nom': 'KOKOLOGO'},
    ],

    // SUD-OUEST - IOBA
    '13-02-01': [
      // SUD-OUEST > IOBA > DANO (classés alphabétiquement)
      {'code': '01', 'nom': 'DANO'},
    ],

    // SUD-OUEST - PONI
    '13-04-01': [
      // SUD-OUEST > PONI > BOUROUM-BOUROUM (classés alphabétiquement)
      {'code': '01', 'nom': 'BOUROUM-BOUROUM'},
    ],

    // HAUTS-BASSINS - HOUET (autres communes)
    '09-01-01': [
      // HAUTS-BASSINS > HOUET > BAMA (classés alphabétiquement)
      {'code': '01', 'nom': 'BAMA'},
      {'code': '02', 'nom': 'SOUNGALODAGA'},
    ],
    '09-01-02': [
      // HAUTS-BASSINS > HOUET > BOBO-DIOULASSO (classés alphabétiquement selon l'image)
      {'code': '01', 'nom': 'BOBO'},
      {'code': '02', 'nom': 'BOBO-DIOULASSO'},
      {'code': '03', 'nom': 'DAFINSO'},
      {'code': '04', 'nom': 'DOUFIGUISSO'},
      {'code': '05', 'nom': 'NOUMOUSSO'},
    ],
    '09-01-09': [
      // HAUTS-BASSINS > HOUET > PENI (classés alphabétiquement)
      {'code': '01', 'nom': 'GNANFOGO'},
      {'code': '02', 'nom': 'KOUMANDARA'},
      {'code': '03', 'nom': 'MOUSSOBADOUGOU'},
      {'code': '04', 'nom': 'PENI'},
    ],
    '09-01-05': [
      // HAUTS-BASSINS > HOUET > KARANGASSO-VIGUE (classés alphabétiquement)
      {'code': '01', 'nom': 'DAN'},
      {'code': '02', 'nom': 'DEREGUAN'},
      {'code': '03', 'nom': 'KARANGASSO VIGUE'},
      {'code': '04', 'nom': 'OUERE'},
      {'code': '05', 'nom': 'SOUMOUSSO'},
    ],

    // HAUTS-BASSINS - KENEDOUGOU
    '09-02-04': [
      // HAUTS-BASSINS > KENEDOUGOU > KOURINION (classés alphabétiquement)
      {'code': '01', 'nom': 'GUENA'},
      {'code': '02', 'nom': 'KOURINION'},
      {'code': '03', 'nom': 'SIDI'},
      {'code': '04', 'nom': 'SIPIGUI'},
      {'code': '05', 'nom': 'TOUSSIAMASSO'},
    ],
    '09-02-03': [
      // HAUTS-BASSINS > KENEDOUGOU > KOLOKO (classés alphabétiquement)
      {'code': '01', 'nom': 'KOKOUNA'},
      {'code': '02', 'nom': 'SIFARASSO'},
    ],
    '09-02-02': [
      // HAUTS-BASSINS > KENEDOUGOU > KANGALA (classés alphabétiquement)
      {'code': '01', 'nom': 'MAHON'},
      {'code': '02', 'nom': 'SOKOURABA'},
      {'code': '03', 'nom': 'WOLONKOTO'},
    ],
    '09-02-06': [
      // HAUTS-BASSINS > KENEDOUGOU > ORODARA (classés alphabétiquement)
      {'code': '01', 'nom': 'ORODARA'},
    ],

    // HAUTS-BASSINS - TUY (autres communes)
    '09-03-01': [
      // HAUTS-BASSINS > TUY > BEKUY (classés alphabétiquement)
      {'code': '01', 'nom': 'ZEKUY'},
    ],
    '09-03-05': [
      // HAUTS-BASSINS > TUY > KOUMBIA (classés alphabétiquement)
      {'code': '01', 'nom': 'KOUMBIA'},
    ],

    // CENTRE-SUD - NAHOURI (autres communes)
    '07-02-01': [
      // CENTRE-SUD > NAHOURI > GUIARO (classés alphabétiquement)
      {'code': '01', 'nom': 'KOLLO'},
      {'code': '02', 'nom': 'OUALEM'},
      {'code': '03', 'nom': 'SARO'},
    ],

    // VILLAGES SUPPLÉMENTAIRES EXTRAITS DE L'IMAGE COMPLÈTE

    // HAUTS-BASSINS - HOUET - TOUSSIANA (villages supplémentaires)
    '09-01-11-villages': [
      // Tous les villages TOUSSIANA d'après l'image (classés alphabétiquement)
      {'code': '01', 'nom': 'TOUSSIANA'},
    ],

    // HAUTS-BASSINS - TUY - SALA (nouvelle commune identifiée)
    '09-03-06': [
      // HAUTS-BASSINS > TUY > SALA (d'après l'image)
      {'code': '01', 'nom': 'SALA'},
      {'code': '02', 'nom': 'SATIRI'},
    ],

    // CASCADES - LERABA - LOUMANA (villages supplémentaires d'après l'image)
    '02-02-04-extra': [
      // Villages supplémentaires pour LOUMANA visibles dans l'image
      {'code': '07', 'nom': 'LOUMANA'}, // Village répété dans l'image
    ],

    // CASCADES - COMOE - SOUBAKANIEDOUGOU (villages supplémentaires)
    '02-01-08-extra': [
      // Villages supplémentaires pour SOUBAKANIEDOUGOU d'après l'image
      {'code': '02', 'nom': 'SOUBAKANIEDOUGOU'}, // Répétitions dans l'image
      {'code': '03', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '04', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '05', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '06', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '07', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '08', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '09', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '10', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '11', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '12', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '13', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '14', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '15', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '16', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '17', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '18', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '19', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '20', 'nom': 'SOUBAKANIEDOUGOU'},
      {'code': '21', 'nom': 'SOUBAKANIEDOUGOU'},
    ],

    // HAUTS-BASSINS - HOUET - TOUSSIANA (toutes les répétitions de l'image)
    '09-01-11-complete': [
      // Toutes les occurrences TOUSSIANA dans l'image
      {'code': '02', 'nom': 'TOUSSIANA'},
      {'code': '03', 'nom': 'TOUSSIANA'},
      {'code': '04', 'nom': 'TOUSSIANA'},
      {'code': '05', 'nom': 'TOUSSIANA'},
      {'code': '06', 'nom': 'TOUSSIANA'},
      {'code': '07', 'nom': 'TOUSSIANA'},
      {'code': '08', 'nom': 'TOUSSIANA'},
      {'code': '09', 'nom': 'TOUSSIANA'},
      {'code': '10', 'nom': 'TOUSSIANA'},
      {'code': '11', 'nom': 'TOUSSIANA'},
      {'code': '12', 'nom': 'TOUSSIANA'},
      {'code': '13', 'nom': 'TOUSSIANA'},
      {'code': '14', 'nom': 'TOUSSIANA'},
    ],

    // HAUTS-BASSINS - TUY - SALA/SATIRI (toutes les occurrences)
    '09-03-06-complete': [
      // Toutes les occurrences SALA/SATIRI dans l'image
      {'code': '03', 'nom': 'SALA'},
      {'code': '04', 'nom': 'SALA'},
      {'code': '05', 'nom': 'SALA'},
      {'code': '06', 'nom': 'SALA'},
      {'code': '07', 'nom': 'SALA'},
      {'code': '08', 'nom': 'SALA'},
      {'code': '09', 'nom': 'SALA'},
      {'code': '10', 'nom': 'SALA'},
      {'code': '11', 'nom': 'SALA'},
      {'code': '12', 'nom': 'SALA'},
      {'code': '13', 'nom': 'SALA'},
      {'code': '14', 'nom': 'SALA'},
      {'code': '15', 'nom': 'SALA'},
      {'code': '16', 'nom': 'SATIRI'},
      {'code': '17', 'nom': 'SATIRI'},
      {'code': '18', 'nom': 'SATIRI'},
      {'code': '19', 'nom': 'SATIRI'},
      {'code': '20', 'nom': 'SATIRI'},
    ],
  };

  // Méthodes utilitaires adaptées au système de codification
  static List<Map<String, dynamic>> getProvincesForRegion(String? codeRegion) {
    if (codeRegion == null) return [];
    return provincesParRegion[codeRegion] ?? [];
  }

  static List<Map<String, dynamic>> getCommunesForProvince(
      String? codeRegion, String? codeProvince) {
    if (codeRegion == null || codeProvince == null) return [];
    final key = '$codeRegion-$codeProvince';
    return communesParProvince[key] ?? [];
  }

  static List<Map<String, dynamic>> getVillagesForCommune(
      String? codeRegion, String? codeProvince, String? codeCommune) {
    if (codeRegion == null || codeProvince == null || codeCommune == null)
      return [];
    final key = '$codeRegion-$codeProvince-$codeCommune';
    return villagesParCommune[key] ?? [];
  }

  // Méthodes de recherche par nom
  static String? getRegionCodeByName(String regionName) {
    for (final region in regionsBurkina) {
      if (region['nom'].toString().toLowerCase() == regionName.toLowerCase()) {
        return region['code'];
      }
    }
    return null;
  }

  static String? getProvinceCodeByName(
      String? codeRegion, String provinceName) {
    if (codeRegion == null) return null;
    final provinces = getProvincesForRegion(codeRegion);
    for (final province in provinces) {
      if (province['nom'].toString().toLowerCase() ==
          provinceName.toLowerCase()) {
        return province['code'];
      }
    }
    return null;
  }

  static String? getCommuneCodeByName(
      String? codeRegion, String? codeProvince, String communeName) {
    if (codeRegion == null || codeProvince == null) return null;
    final communes = getCommunesForProvince(codeRegion, codeProvince);
    for (final commune in communes) {
      if (commune['nom'].toString().toLowerCase() ==
          communeName.toLowerCase()) {
        return commune['code'];
      }
    }
    return null;
  }

  // Méthodes de recherche inverse (retrouver la hiérarchie)
  static Map<String, String?> findLocationHierarchy({
    String? regionName,
    String? provinceName,
    String? communeName,
  }) {
    String? regionCode;
    String? provinceCode;
    String? communeCode;

    // Recherche de la région
    if (regionName != null) {
      regionCode = getRegionCodeByName(regionName);
    }

    // Recherche de la province
    if (provinceName != null && regionCode != null) {
      provinceCode = getProvinceCodeByName(regionCode, provinceName);
    }

    // Recherche de la commune
    if (communeName != null && regionCode != null && provinceCode != null) {
      communeCode = getCommuneCodeByName(regionCode, provinceCode, communeName);
    }

    return {
      'regionCode': regionCode,
      'provinceCode': provinceCode,
      'communeCode': communeCode,
    };
  }

  // Validation de la hiérarchie géographique
  static bool validateHierarchy({
    String? codeRegion,
    String? codeProvince,
    String? codeCommune,
  }) {
    if (codeRegion != null && codeProvince != null) {
      final provinces = getProvincesForRegion(codeRegion);
      if (!provinces.any((p) => p['code'] == codeProvince)) {
        return false;
      }
    }

    if (codeRegion != null && codeProvince != null && codeCommune != null) {
      final communes = getCommunesForProvince(codeRegion, codeProvince);
      if (!communes.any((c) => c['code'] == codeCommune)) {
        return false;
      }
    }

    return true;
  }

  // Formatage des codes de localisation pour affichage
  static String formatLocationCode({
    String? regionName,
    String? provinceName,
    String? communeName,
    String? villageName,
  }) {
    final hierarchy = findLocationHierarchy(
      regionName: regionName,
      provinceName: provinceName,
      communeName: communeName,
    );

    final regionCode = hierarchy['regionCode'] ?? '00';
    final provinceCode = hierarchy['provinceCode'] ?? '00';
    final communeCode = hierarchy['communeCode'] ?? '00';

    // Format: 01-23-099 / Région-Province-Commune-Village
    final codesPart = '$regionCode-$provinceCode-$communeCode';
    final namesPart = [regionName, provinceName, communeName, villageName]
        .where((name) => name != null && name.isNotEmpty)
        .join('-');

    return '$codesPart / $namesPart';
  }

  // Formatage à partir d'un objet localisation
  static String formatLocationCodeFromMap(Map<String, String> localisation) {
    return formatLocationCode(
      regionName: localisation['region'],
      provinceName: localisation['province'],
      communeName: localisation['commune'],
      villageName: localisation['village'],
    );
  }
}

// Classe utilitaire pour maintenir la compatibilité avec l'ancien système
class GeographieUtils {
  /// Obtient toutes les provinces d'une région donnée (compatibilité)
  static List<String> getProvincesByRegion(String region) {
    final regionCode = GeographieData.getRegionCodeByName(region);
    if (regionCode == null) return [];

    final provinces = GeographieData.getProvincesForRegion(regionCode);
    return provinces.map((p) => p['nom'].toString()).toList();
  }

  /// Obtient toutes les communes d'une province donnée (compatibilité)
  static List<String> getCommunesByProvince(String province) {
    // Recherche dans toutes les régions pour trouver la province
    for (final regionEntry in GeographieData.provincesParRegion.entries) {
      final regionCode = regionEntry.key;
      final provinces = regionEntry.value;

      for (final prov in provinces) {
        if (prov['nom'].toString().toLowerCase() == province.toLowerCase()) {
          final provinceCode = prov['code'];
          final communes =
              GeographieData.getCommunesForProvince(regionCode, provinceCode);
          return communes.map((c) => c['nom'].toString()).toList();
        }
      }
    }
    return [];
  }

  /// Obtient tous les villages d'une commune donnée (compatibilité)
  static List<String> getVillagesByCommune(String commune) {
    // Recherche dans toutes les communes pour trouver les villages
    for (final villageEntry in GeographieData.villagesParCommune.entries) {
      final key = villageEntry.key;
      final parts = key.split('-');
      if (parts.length == 3) {
        final regionCode = parts[0];
        final provinceCode = parts[1];
        final communeCode = parts[2];

        final communes =
            GeographieData.getCommunesForProvince(regionCode, provinceCode);
        final targetCommune = communes
            .where(
              (c) =>
                  c['code'] == communeCode &&
                  c['nom'].toString().toLowerCase() == commune.toLowerCase(),
            )
            .firstOrNull;

        if (targetCommune != null) {
          return villageEntry.value.map((v) => v['nom'].toString()).toList();
        }
      }
    }
    return [];
  }

  /// Trouve la région d'une province donnée (compatibilité)
  static String? getRegionByProvince(String province) {
    for (final regionEntry in GeographieData.provincesParRegion.entries) {
      final regionCode = regionEntry.key;
      final provinces = regionEntry.value;

      if (provinces.any(
          (p) => p['nom'].toString().toLowerCase() == province.toLowerCase())) {
        final region = GeographieData.regionsBurkina
            .where(
              (r) => r['code'] == regionCode,
            )
            .firstOrNull;
        return region?['nom'];
      }
    }
    return null;
  }

  /// Trouve la province d'une commune donnée (compatibilité)
  static String? getProvinceByCommune(String commune) {
    for (final communeEntry in GeographieData.communesParProvince.entries) {
      final key = communeEntry.key;
      final communes = communeEntry.value;

      if (communes.any(
          (c) => c['nom'].toString().toLowerCase() == commune.toLowerCase())) {
        final parts = key.split('-');
        if (parts.length == 2) {
          final regionCode = parts[0];
          final provinceCode = parts[1];

          final provinces = GeographieData.getProvincesForRegion(regionCode);
          final province = provinces
              .where(
                (p) => p['code'] == provinceCode,
              )
              .firstOrNull;
          return province?['nom'];
        }
      }
    }
    return null;
  }

  /// Trouve la commune d'un village donné (compatibilité)
  static String? getCommuneByVillage(String village) {
    for (final villageEntry in GeographieData.villagesParCommune.entries) {
      final key = villageEntry.key;
      final villages = villageEntry.value;

      if (villages.any(
          (v) => v['nom'].toString().toLowerCase() == village.toLowerCase())) {
        final parts = key.split('-');
        if (parts.length == 3) {
          final regionCode = parts[0];
          final provinceCode = parts[1];
          final communeCode = parts[2];

          final communes =
              GeographieData.getCommunesForProvince(regionCode, provinceCode);
          final commune = communes
              .where(
                (c) => c['code'] == communeCode,
              )
              .firstOrNull;
          return commune?['nom'];
        }
      }
    }
    return null;
  }

  /// Recherche géographique complète (compatibilité)
  static Map<String, String?> getCompleteLocation(String village) {
    final commune = getCommuneByVillage(village);
    final province = commune != null ? getProvinceByCommune(commune) : null;
    final region = province != null ? getRegionByProvince(province) : null;

    return {
      'region': region,
      'province': province,
      'commune': commune,
      'village': village.toUpperCase(),
    };
  }

  /// Valide si une hiérarchie géographique est cohérente (compatibilité)
  static bool validateHierarchy({
    String? region,
    String? province,
    String? commune,
    String? village,
  }) {
    if (region != null && province != null) {
      if (!getProvincesByRegion(region).contains(province.toUpperCase())) {
        return false;
      }
    }

    if (province != null && commune != null) {
      if (!getCommunesByProvince(province).contains(commune.toUpperCase())) {
        return false;
      }
    }

    if (commune != null && village != null) {
      if (!getVillagesByCommune(commune).contains(village.toUpperCase())) {
        return false;
      }
    }

    return true;
  }

  /// Recherche par nom partiel - régions (compatibilité)
  static List<String> searchRegions(String query) {
    return GeographieData.regionsBurkina
        .where((r) =>
            r['nom'].toString().toLowerCase().contains(query.toLowerCase()))
        .map((r) => r['nom'].toString())
        .toList();
  }

  /// Recherche par nom partiel - provinces (compatibilité)
  static List<String> searchProvinces(String query, {String? region}) {
    final provinces = region != null
        ? getProvincesByRegion(region)
        : GeographieData.provincesParRegion.values
            .expand((provinces) => provinces.map((p) => p['nom'].toString()))
            .toList();
    return provinces
        .where((p) => p.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Recherche par nom partiel - communes (compatibilité)
  static List<String> searchCommunes(String query, {String? province}) {
    final communes = province != null
        ? getCommunesByProvince(province)
        : GeographieData.communesParProvince.values
            .expand((communes) => communes.map((c) => c['nom'].toString()))
            .toList();
    return communes
        .where((c) => c.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Recherche par nom partiel - villages (compatibilité)
  static List<String> searchVillages(String query, {String? commune}) {
    final villages = commune != null
        ? getVillagesByCommune(commune)
        : GeographieData.villagesParCommune.values
            .expand((villages) => villages.map((v) => v['nom'].toString()))
            .toList();
    return villages
        .where((v) => v.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

// Liste de compatibilité pour l'ancien système
const List<String> regionsBurkina = [
  'BOUCLE DU MOUHOUN',
  'CASCADES',
  'CENTRE',
  'CENTRE-EST',
  'CENTRE-NORD',
  'CENTRE-OUEST',
  'CENTRE-SUD',
  'EST',
  'HAUTS-BASSINS',
  'NORD',
  'PLATEAU-CENTRAL',
  'SAHEL',
  'SUD-OUEST',
];

// Maps de compatibilité pour l'ancien système
final Map<String, List<String>> provincesParRegion = {
  for (final region in GeographieData.regionsBurkina)
    region['nom'].toString():
        GeographieData.getProvincesForRegion(region['code'])
            .map((p) => p['nom'].toString())
            .toList(),
};

final Map<String, List<String>> communesParProvince = {
  for (final regionEntry in GeographieData.provincesParRegion.entries)
    for (final province in regionEntry.value)
      province['nom'].toString(): GeographieData.getCommunesForProvince(
              regionEntry.key, province['code'])
          .map((c) => c['nom'].toString())
          .toList(),
};

final Map<String, List<String>> villagesParCommune = {
  for (final villageEntry in GeographieData.villagesParCommune.entries)
    () {
      final parts = villageEntry.key.split('-');
      if (parts.length == 3) {
        final communes =
            GeographieData.getCommunesForProvince(parts[0], parts[1]);
        final commune =
            communes.where((c) => c['code'] == parts[2]).firstOrNull;
        if (commune != null) {
          return commune['nom'].toString();
        }
      }
      return '';
    }(): villageEntry.value.map((v) => v['nom'].toString()).toList(),
}..removeWhere((key, value) => key.isEmpty);
