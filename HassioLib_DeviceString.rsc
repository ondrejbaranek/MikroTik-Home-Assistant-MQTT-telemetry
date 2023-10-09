# Use
# local DeviceString [parse [system/script/get "HassioLib_DeviceString" source]]
# $DeviceString
#
local ID
local LowercaseHex [parse [system/script/get "HassioLib_LowercaseHex" source]]
# Get serial
    if ([/system/resource/get board-name] != "CHR") do={
    set ID ("\"".[/system/routerboard get serial-number]."\"");#ID
    } else={
    set ID ("\"".[system/license/get system-id ]."\"")
    }

        local Name [/system/identity/get name];       #Name
        local Model [system/resource/get board-name]; #Mode
        local CSW   [/system/resource/get version ];  #SW
        local Manu [/system/resource/get platform];   #Manufacturer


# Get Ethernet MAC addresses
foreach iface in=[interface/ethernet/find ] do={
        set $ID ($ID.",\"".\
            [$LowercaseHex input=[/interface/ethernet/get $iface mac-address]].\
            "\"")
    if ([/interface/ethernet/get $iface mac-address] != [/interface/ethernet/get $iface orig-mac-address]) do= {
        set $ID ($ID.",\"".\
            [$LowercaseHex input=[/interface/ethernet/get $iface orig-mac-address]].\
            "\"")
    }
}

# Get Wi-Fi MAC addresses
if ([len [system/package/find name="wifiwave2"]]  =0 ) do={
    local Condition [parse "local a [/interface/wireless/ find interface-type!=\"virtual\"];return \$a"]
    local Action [parse "local a [interface/wireless/get \$1 mac-address];return \$a"]
    foreach iface in=[$Condition] do={
        set $ID ($ID.",\"".\
            [$LowercaseHex input=[$Action $iface]].\
            "\"")
    }
}\
# Get Wi-Fi Wave2 MAC Addresses
else={
    local Condition [parse "local a [/interface/wifiwave2/radio/find];return \$a"]
    local Action [parse "local a [/interface/wifiwave2/radio/get \$1 radio-mac];return \$a"]
    foreach iface in=[$Condition] do={
        set $ID ($ID.",\"".\
            [$LowercaseHex input=[$Action $iface]].\
            "\"")
    }
}

# Find a reasonable link to WebFig if enabled.
local urldomain
local ipaddress

foreach bridge in=[/interface/bridge/find] do={
    foreach AddressIndex in=[ip/address/find where interface=[/interface/bridge/get $bridge name]] do={
        set ipaddress [/ip/address/get $AddressIndex address]
        set $ipaddress [:pick $ipaddress 0 [:find $ipaddress "/"]]
       foreach UrlIndex in=[/ip/dns/static/ find address=$ipaddress name] do={
            set $urldomain [/ip/dns/static/ get $UrlIndex name  ]
        }
    }
}
if ([len $ipaddress]=0) do={
    foreach addr in=[/ip/address/find] do={
        local TempAddress [/ip/address/get $addr address]
        set $TempAddress [:pick $TempAddress 0 [:find $TempAddress "/"]]
        foreach UrlIndex in=[/ip/dns/static/find address=$TempAddress] do={
            local TempUrlDomain [ip/dns/static/get $UrlIndex name]
            if ([len $TempUrlDomain]>0) do={set $urldomain $TempUrlDomain}
        }
    }
}
if ([len $urldomain]>0) do={set $ipaddress $urldomain}

local url
if ([len $ipaddress] >0) do={
    :if (! [/ip/service/get www-ssl disabled ]) \
        do={:set $url ",\"cu\":\"https://$ipaddress/\""} \
    else={if (! [/ip/service/get www disabled]) \
        do={:set $url ",\"cu\":\"http://$ipaddress/\""}}
}
        #-------------------------------------------------------
        #Build device string
        #-------------------------------------------------------
        global dev "\"dev\":{\
            \"ids\":[$ID],\
            \"name\":\"$Name\",\
            \"mdl\":\"$Model\",\
            \"sw\":\"$CSW\",\
            \"mf\":\"$Manu\"$url}"


return $dev