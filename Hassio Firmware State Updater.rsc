{
    global discoverypath "homeassistant/"
    global domainpath "update/"

    #-------------------------------------------------------
    #Get variables to build device string
    #-------------------------------------------------------
    #ID
    global ID [/system/routerboard get serial-number] 

    global poststate do= {
        global discoverypath
        global domainpath
        global ID
        #post Routerboard firmware
        local state "{\"installed_version\":\"$cur\",\
            \"latest_version\":\"$new\"}"
        /iot/mqtt/publish broker="Home Assistant" message=$state topic="$discoverypath$domainpath$ID/$name/state"
    }
    #-------------------------------------------------------
    #Handle routerboard firmware for non CHR
    #-------------------------------------------------------
    if ([/system/resource/get board-name] != "CHR") do={
        #Get routerboard firmware
        local cur [/system/routerboard/ get current-firmware]
        local new [/system/routerboard/ get upgrade-firmware]

        #post Routerboard firmware
        $poststate name="RouterBOARD" cur=$cur new=$new
    }

    #-------------------------------------------------------
    #Handle RouterOS
    #-------------------------------------------------------
    #Get system software
    local cur [ /system/package/update/ get installed-version ]
    local new [ /system/package/update/ get latest-version ]

    $poststate name="RouterOS" cur=$cur new=$new

    #-------------------------------------------------------
    #Handle LTE interfaces
    #-------------------------------------------------------
    #Count nummer of LTE interfaces

    :foreach iface in=[/interface/lte/ find] do={
    local ifacename [/interface/lte get $iface name]

    #Get manufacturer and model for LTE interface
    global lte [ [/interface/lte/monitor [/interface/lte get $iface name] once as-value] manufacturer]
        if ($lte->"manufacturer"="\"MikroTik\"") do={
            {
            #build config for LTE
            local modemname [:pick ($lte->"model")\
                ([:find ($lte->"model") "\"" -1] +1)\
                [:find ($lte->"model") "\"" [:find ($lte->"model") "\"" -1]]]

            #Get firmware version for LTE interface
            local Firmware [/interface/lte firmware-upgrade [/interface/lte get $iface name] once as-value ]
            local cur ($Firmware->"installed")
            local new ($Firmware->"latest")

            $poststate name=$modemname cur=$cur new=$new
            }
        }
    }
}