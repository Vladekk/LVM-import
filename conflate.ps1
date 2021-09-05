#!/usr/bin/pwsh
# License is MIT.
# Author Vladekk - vlad@izvne.com

# This script is needed to split imported dataset, download same area from overpass
# and conflate using Hootenanny.

############### config #######################
# Each run of this script produces new conflated extentData 
# allows comparison of result after config changes        
$produceNewConflationOnEachRun = $false

### translate import data and split into 8x8 grid


#download all Latvia osm from geofabrik (not used as file is too big to proce ||  = $tss)
#$downloadAndSplitGeofabrik = $false

$sourceName = "input-original.osm"

#$algorithm = "NetworkAlgorithm.conf"
$algorithm = "UnifyingAlgorithm.conf"
$confType = "ReferenceConflation.conf"
#$confType = "DifferentialConflation.conf"
$translatedInputName = "import-translated.osm"
$griddedBaseName = "import-gridded"
$osmBaseName = "osm-source"
$importGriddedName = "$griddedBaseName.osm"
$tilesInGridCount = 8
$gridName = "grid-$tilesInGridCount.osm"
#$osmGeofabrikName = "geofabrik-trimmed.osm"


$skip = 60
$take = 1
$searchRadiusHighway = 20

############### end config #######################

$targetFnPrefix = "conflated"
$changesFnPrefix = "changes-" + $targetFnPrefix
$downloadFreshFromLvm = $true
$forceTranslateImport = $false
$markHootChangedAsModified = $true
$forceReconflate = $false
#force fetch fresh data from overpass, otherwise use existing data downloaded in previous runs
$forceRedownloadFromOsm = $false

$lvmDatasetUrl = "https://lvmgeo.lvm.lv/PublicData/SHP/LVM_MEZA_AUTOCELI.zip"
$rootDir = "/mnt/d/Docs/Maps/LVM-OSM-IMPORT-2021/cur/"
$workingDir = 'working-dir'

Set-Location $rootDir
New-Item  -ItemType Directory  temp -ErrorAction Ignore
New-Item  -ItemType Directory $workingDir -ErrorAction Ignore

# start

$lvmFileInfo = Invoke-WebRequest -Method Head  $lvmDatasetUrl
$lvmEtag = $lvmFileInfo.Headers.ETag[0].Trim('"').Replace(":", "")
$lvmFilename = "$lvmEtag.zip"




if ($downloadFreshFromLvm) {
    
    if (-not (Test-Path "./temp/$lvmFilename")) {
        Set-Location temp
        wget -O $lvmFilename $lvmDatasetUrl    
        unzip -o $lvmFilename
        # required to process encoding properly from CP1257 to UTF8
        Remove-Item out.geojson -ErrorAction Ignore
        ogr2ogr --config SHAPE_ENCODING CP1257 -f "geojson"  out.geojson *.shp
        hoot convert ./out.geojson ../$workingDir/input-original.osm
        Set-Location ..
    }
}
Set-Location $workingDir

if (-not (Test-Path $translatedInputName) || $forceTranslateImport) {
    hoot convert  -D schema.translation.script=../lvm.js ./$sourceName ./$translatedInputName
    hoot task-grid ./$translatedInputName  ./$gridName $tilesInGridCount --uniform
    hoot split ./$gridName $translatedInputName $importGriddedName
}


# # legacy        
# if ($downloadAndSplitGeofabrik) {
#     wget http://download.geofabrik.de/europe/latvia-latest.osm.pbf
#     wget http://download.geofabrik.de/europe/latvia-latest.osm.pbf
#     $lvExtent = hoot extent ./import-translated.osm 
#     $lvExtent = $lvExtent[2].Split(' ')[3];
#     hoot convert ./latvia-latest.osm.pbf ./latvia-latest.osm
#     hoot convert -D bounds=$lvExtent ./latvia-latest.osm ./geofabrik-trimmed.osm
#     hoot split ./$gridName ./$osmGeofabrikName ./geofabrik-gridded.osm
# }
        

Get-ChildItem -Filter *$griddedBaseName-*.osm |
Select-Object -Skip $skip -First $take |
Where-Object { $_.Length -gt 174 } |
ForEach-Object { 
    $griddedCellNumber = $_.Name.Replace($griddedBaseName + '-', "").Replace(".osm", "")
    $extentData = hoot extent $_.Name;
    $cellExtent = $extentData[2].Split(' ')[3];      
    $osmFileName = "$osmBaseName-$griddedCellNumber.osm"
    $importFileName = $_.Name
             
    #$extentArr = $cellExtent.Split(',');
    # convert hoot extent to overpass bbox format

    # legacy
    # $bbox = $extentArr[1] + "," + $extentArr[0] + "," + $extentArr[3] + "," + $extentArr[2];
           
    # if (-not (Test-Path ./$osmFileName) -or $forceRedownloadFromOsm) {   
    # true
    #         curl -X GET `
    #             --location "https://overpass-api.de/api/interpreter" `
    #             -H "Content-Type: text/plain" `
    #             -d "[out:xml][timeout:90][bbox:$bbox];  ( nwr; ); out meta;" `
    #             > $osmFileName
    #     }
    #     else {
    #         hoot convert -D bounds=$cellExtent https://vladekk:w2135itbp@api.openstreetmap.org/api/0.6/map $osmFileName
    #     }
    # }
    if (-not (Test-Path ./$osmFileName) -or $forceRedownloadFromOsm) {   
        hoot convert -D bounds=$cellExtent https://vladekk:w2135itbp@api.openstreetmap.org/api/0.6/map $osmFileName
    }
    $conflatedOutName = "$targetFnPrefix-$griddedCellNumber-$algorithm-$confType.osm"
        
    if ($produceNewConflationOnEachRun) {
        # each run of this script produces new conflated extentData 
        # allows comparison of result after config changes
        $runNum = 0;
        while (Test-Path ./$conflatedOutName) {
            $runNum++;
            $conflatedOutName = "$targetFnPrefix-$number-$algorithm-$confType-$runNum.osm"
        }
    }

    if ($forceReconflate -or (-not (Test-Path $conflatedOutName))) {

        #            -D snap.unconnected.ways.review.snapped.ways=true `
        hoot conflate `
            -C $confType -C $algorithm `
            -D search.radius.highway=$searchRadiusHighway `
            -D reader.add.source.datetime=false `
            -D writer.include.circular.error.tags=false `
            -D writer.include.debug.tags=true `
            -D conflate.post.ops+=UnconnectedWaySnapper `
            -D snap.unconnected.ways.snap.tolerance=8 `
            -D match.creators="hoot::HighwayMatchCreator;" `
            -D map.cleaner.transforms-=hoot::UnlikelyIntersectionRemover `
            ./$osmFileName `
            ./$importFileName `
            $conflatedOutName
        # produces pretty strange result, but fine for just checking where changes are
        If ($lastExitCode -eq "0") {         
            hoot changeset-derive ./$osmFileName $conflatedOutName conflated-$griddedCellNumber.osc
        }
    }
        
    
    

    if ($markHootChangedAsModified -and (Test-Path $conflatedOutName)) {
        Write-Output "Reading conflated file $conflatedOutName"
        [xml]$osm = Get-Content $conflatedOutName

        Write-Output "Marking changed nodes"
        $count = 0;
        $allCount = 0;
        $hootTagsCount =0;
        $osm.DocumentElement.ChildNodes 
        | Where-Object { $_.Name -eq "node" -or ($_.Name -eq "way") -or ($_.Name -eq "relation") } 
        | ForEach-Object {
            $allCount++;
            $hootStatusNodes = $_.ChildNodes.Where( { ($_.Name -eq "tag" -and ($_.k -eq "hoot:status") -and (($_.v -eq "3") -or ($_.v -eq "2"))  ) })
            $isStatus3 = $hootStatusNodes.Count -gt 0
            if ($isStatus3) {
                $count++;
                
                $actionAttr = $_.OwnerDocument.CreateAttribute("action");
                $actionAttr.Value = "modify";
                $_.Attributes.Append($actionAttr) > $null;                                              
            }    
            $currentFeatureNode = $_
            $hootStatusNodes = $_.ChildNodes.Where( { ($_.Name -eq "tag" -and (
                            ($_.k -in "source:datetime","error:circular") -or ($_.k.ToString().StartsWith("hoot:"))                                
                        )) })
            $hootTagsCount +=  $hootStatusNodes.Count
            $hootStatusNodes | ForEach-Object { $currentFeatureNode.RemoveChild($_) }  > $null;          

            if ($allCount % 10000 -eq 0) {
                Write-Output "Processed $allCount features, found $count changed featues, removed $hootTagsCount hoot debug tags"
            }        
        }
        
        $changesFileName = "$changesFnPrefix-$griddedCellNumber-$algorithm-$confType.osm"
        Write-Output "Overall, processed $allCount features"
        if ($count -gt 0) {
            Write-Output "Found $count changed features, writing output file $changesFileName"
        }
        else {
            throw "found zero changed features, which  is suspicious"            
        }
        
        $osm.Save("$workingDir/$changesFileName")
    }        
}        
          
cd ..