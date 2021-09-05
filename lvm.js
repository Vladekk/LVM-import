function initialize() {
// The print method simply prints the string representation to stdout
    print("Initializing.")
}

// an optional finalize function that gets called once after all
// translateAttribute calls.
function finalize() {
// the debug method prints to stdout when --debug has been specified on
// the hoot command line. (DEBUG log level)
    debug("Finalizing.");
}

// A very simple function for translating NFDDv4s to OSM:

function translateToOgr(tags, elementType, geometryType) {
    // var attrs = {};
    // if (
    //     name in
    //     tags
    // ) {
    //     attrs[NAM]
    //         = tags[name]
    //     ;
    // }
    // attrs[TYP]
    //     = 0;
    // if (tags[highway] == road) {
    //     attrs[TYP]
    //         = 1;
    // } else if (tags[
    //     highway] == motorway) {
    //     attrs[TYP]
    //         = 41;
    // }
    // return {attrs: attrs, tableName: "LAP030"};
}

// Translates LVM-celi schema to OSM schema
function translateToOsm(attrs, layerName) {
    var tags = {};
    if (attrs['ROADNAME']) {
        tags['name'] = attrs['ROADNAME'];
        tags['surface'] = 'gravel';
        tags['highway'] = 'unclassified';
    } else {
        tags['highway'] = 'track';
        tags['surface'] = 'unpaved';
    }

    var distri = {"22121":"Ērģemes",
    "22122":"Strenču",
    "22123":"Silvas",
    "22124":"Sikšņu",
    "22125":"Melnupes",
    "22126":"Mālupes",
    "22127":"Lejasciema",
    "22128":"Pededzes",
    "22221":"Alsungas",
    "22222":"Rendas",
    "22223":"Akmensraga",
    "22224":"Apriķu",
    "22225":"Ventas DK",
    "22226":"Remtes",
    "22227":"Grobiņas",
    "22228":"Krīvukalna",
    "22229":"Pampāļu",
    "22230":"Zvārdes",
    "22231":"Nīcas",
    "22321":"Viesītes",
    "22322":"Ābeļu",
    "22323":"Preiļu",
    "22324":"Aknīstes",
    "22325":"Nīcgales",
    "22326":"Krāslavas",
    "22327":"Sventes",
    "22421":"Salacgrīvas",
    "22422":"Rūjienas",
    "22423":"Piejūras",
    "22424":"Limbažu",
    "22425":"Valmieras",
    "22426":"Ropažu",
    "22427":"Vēru",
    "22428":"Piebalgas",
    "22521":"Ogres",
    "22522":"Kokneses",
    "22523":"Skaistkalnes",
    "22524":"Jaunjelgavas",
    "22525":"Seces",
    "22526":"Vecumnieku",
    "22527":"Bauskas",
    "22528":"Ērberģes",
    "22621":"Engures",
    "22622":"Kandavas",
    "22623":"Misas",
    "22624":"Dobeles",
    "22625":"Īles",
    "22626":"Tērvetes",
    "22626":"Līvbērzes",
    "22628":"Klīves",
    "22721":"Grīņu",
    "22722":"Zilokalnu",
    "22723":"Rindas",
    "22724":"Raķupes",
    "22725":"Ventas ZK",
    "22726":"Mētru",
    "22727":"Vanemas",
    "22728":"Mērsraga",
    "22729":"Usmas",
    "22821":"Madonas",
    "22822":"Lubānas",
    "22823":"Žīguru",
    "22824":"Balvu",
    "22825":"Rēzeknes",
    "22826":"Kārsavas",
    "22827":"Ludzas"};

//    tags['fixme'] = 'imported, validate';    

    if (attrs['lvm_distri'] && distri[attrs['lvm_distri']] ) {
        tags['name:forestry_district']=distri[attrs['lvm_distri']];
        tags['ref:forestry_district'] = attrs['lvm_distri'];
    }

    tags['source'] = 'LVM:LVM meža ceļi';    
    tags['operator'] = 'Latvijas valsts meži';    
    tags['operator:abbr'] = 'LVM';    
    tags['operator:website'] = 'https://www.lvm.lv';    
    tags['operator:wikipedia'] = 'https://lv.wikipedia.org/wiki/Latvijas_valsts_me%C5%BEi';    
 
    
    
    return tags;
}
