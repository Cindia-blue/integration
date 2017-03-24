*** Settings ***
Resource    ../../common.robot
Library     BuiltIn
Library     Collections
Library     RequestsLibrary
Library     OperatingSystem
Library     json
Library     HttpLibrary.HTTP

*** Variables ***
${extsys_path}   /openoapi/extsys/v1
${multivim_path}   /openoapi/multivim-vio/v1

${accept_status}   202
${success_status}   200
${delete_status}   204
${invalid_status}   404

${admin}   admin

${image_name}   ubuntu-14.04-server-amd64

${net_name}   vio-net
${subnet_name}   vio-subnet
${subnet_cidr}   10.0.1.0/24

${port_name}   vio-port
${port_ip}    10.0.1.2

${status}   ACTIVE

*** Test Cases ***
Get vio vim
    ${headers}    Create Dictionary    Content-Type=application/json    Accept=application/json
    Create Session    msb_session    http://${MSB_ADDR}    headers=${headers}
    ${resp}=  Get Request    msb_session    ${extsys_path}/vims
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${vim_id}    ${response_json[0]['vimId']}

    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/tenants?name=${admin}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${tenant_id}    ${response_json['tenants'][0]['id']}

    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images?name=${image_name}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    ${response_json}    json.loads    ${resp.content}
    ${respDataLength}    Get Length    ${response_json['images']}
    Should Be True    ${respDataLength} >= 1
    Set Suite Variable    ${image_id}    ${response_json['images'][0]['id']}

VLAN Network Create
    [Documentation]   Create vlan network
    ${body}    Create Dictionary    name=${net_name}    shared=true    routerExternal=false
    ...    networkType=vlan   vlanTransparent=false    segmentationId=200
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/networks    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Integers   ${response_json['returnCode']}   1
    Set Suite Variable    ${net_id}    ${response_json['id']}
    Set Suite Variable    ${phy_net}    ${response_json['physicalNetwork']}

    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/networks/${net_id}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Integers   ${response_json['segmentationId']}   200
    Should Be Equal As Strings   ${response_json['status']}   ${status}
    Should Be Equal As Strings   ${response_json['name']}   ${net_name}
    Should Be Equal As Strings   ${response_json['networkType']}   vlan
    Should Be True    ${response_json['shared']}
    Should Not Be True   ${response_json['routerExternal']}

Subnet Create
    Should Be Equal As Strings  ${PREV TEST STATUS}     PASS    Not create subnet if create network failed
    [Documentation]   Create subnet
    ${body}    Create Dictionary    name=${subnet_name}    networkId=${net_id}    ipVersion=4
    ...    enableDhcp=false   cidr=${subnet_cidr}
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/subnets    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${subnet_id}    ${response_json['id']}

Port Create
    Should Be Equal As Strings  ${PREV TEST STATUS}     PASS    Not create port if create subnet failed
    [Documentation]   Create port
    ${body}    Create Dictionary    name=${port_name}    networkId=${net_id}    subnetId=${subnet_id}
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/ports    ${body}
    Should Be Equal As Integers   ${resp.status_code}    ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${port_id}    ${response_json['id']}

Duplicate Flat Network Create
    [Documentation]   Create duplicate flat network
    ${body}    Create Dictionary    name=${net_name}    shared=false    routerExternal=false
    ...    networkType=flat   vlanTransparent=false
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/networks    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings    ${response_json['id']}   ${net_id}
    Should Be Equal As Integers   ${response_json['returnCode']}   0
    Should Be True    ${response_json['shared']}

Clean up network, subnet and port
    [Documentation]   Clean up network, subnet, port
    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/ports/${port_id}
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}

    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/subnets/${subnet_id}
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}

    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/networks/${net_id}
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}

Multi-Type Network Create and delete
    [Documentation]   Create flat, vxlan network
    @{ITEMS}    Create List    flat    vxlan
    :FOR   ${ITEM}   IN   @{ITEMS}
    \    Log   Create ${ITEM} network
    \    ${body}    Create Dictionary    name=${ITEM}    shared=false    routerExternal=true
    \    ...    networkType=${ITEM}   vlanTransparent=false    physicalNetwork=${phy_net}
    \    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/networks    ${body}
    \    Should Be Equal As Integers   ${resp.status_code}   ${accept_status}
    \    ${response_json}    json.loads    ${resp.content}
    \    Should Be Equal As Integers   ${response_json['returnCode']}   1
    \    Set Suite Variable    ${net_id}    ${response_json['id']}
    \    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/networks/${net_id}
    \    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    \    ${response_json}    json.loads    ${resp.content}
    \    Should Be Equal As Strings   ${response_json['status']}   ${status}
    \    Should Be Equal As Strings   ${response_json['name']}   ${ITEM}
    \    Should Be Equal As Strings   ${response_json['networkType']}   ${ITEM}
    \    Should Not Be True    ${response_json['shared']}
    \    Should Be True   ${response_json['routerExternal']}
    \    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/networks/${net_id}
    \    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}
