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

${net_name}   server-net

${subnet_name}   server-subnet
${subnet_cidr}   10.0.1.0/24

${port_name_1}   server-port-1
${port_name_2}   server-port-2

${vol_name}   server-vol
${vol_size}   5
${vol_status}   available
${attach_status}   attached

${flavor_name}   server-flavor
${flavor_vcpu}   2
${flavor_memory}   2048
${flavor_disk}   5
${flavor_index}   100

${server_name_image}   vio-image-server
${image_vol}   image-vol
${server_name_vol}   vio-vol-server
${server_status}   ACTIVE

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

Network create
    Should Be Equal As Strings  ${PREV TEST STATUS}     PASS    Not create net if resources get failed
    [Documentation]   Create Network subnet and port
    ${body}    Create Dictionary    name=${net_name}    shared=true    routerExternal=false
    ...    networkType=flat   vlanTransparent=false
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/networks    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${net_id}    ${response_json['id']}

    ${body}    Create Dictionary    name=${subnet_name}    networkId=${net_id}    ipVersion=4
    ...    enableDhcp=false   cidr=${subnet_cidr}
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/subnets    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${subnet_id}    ${response_json['id']}

    ${body}    Create Dictionary    name=${port_name_1}    networkId=${net_id}    subnetId=${subnet_id}
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/ports    ${body}
    Should Be Equal As Integers   ${resp.status_code}    ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${port_id_1}    ${response_json['id']}

    ${body}    Create Dictionary    name=${port_name_2}    networkId=${net_id}    subnetId=${subnet_id}
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/ports    ${body}
    Should Be Equal As Integers   ${resp.status_code}    ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${port_id_2}    ${response_json['id']}

Flavor create
    Should Be Equal As Strings  ${PREV TEST STATUS}     PASS    Not create flavor if net create failed
    [Documentation]   Create flavor
    ${body}    Create Dictionary    name=${flavor_name}    vcpu=${flavor_vcpu}    memory=${flavor_memory}
    ...    isPublic=True    disk=${flavor_disk}    id=${flavor_index}
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/flavors    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${flavor_id}    ${response_json['id']}

Volume create for server
    [Documentation]   Create volume for image
    ${body}    Create Dictionary    name=${image_vol}    volumeSize=${vol_size}    imageId=${image_id}
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/volumes    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${image_vol_id}    ${response_json['id']}

    Sleep  90s    # Waiting for volume create done
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/volumes/${image_vol_id}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings   ${response_json['status']}  ${vol_status}

Create server boot from image
    Should Be Equal As Strings  ${PREV TEST STATUS}     PASS    Not create server if flavor create failed
    [Documentation]   Create server boot from image
    ${boot}    Create Dictionary    type=2    imageId=${image_id}
    ${portid}    Create Dictionary    portId=${port_id_1}
    ${nic_array}    Create List   ${portid}

    ${volumeid}   Create Dictionary  volumeId=${image_vol_id}
    ${vol_array}   Create List  ${volumeid}

    ${body}    Create Dictionary    name=${server_name_image}    boot=${boot}    flavorId=${flavor_id}
    ...   nicArray=${nic_array}   volumeArray=${vol_array}
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/servers    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Integers   ${response_json['returnCode']}   1
    Set Suite Variable    ${server_image_id}    ${response_json['id']}

    Sleep  60s   # Waiting for server create done
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/servers/${server_image_id}   # Server get
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings   ${response_json['status']}   ${server_status}

    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/volumes/${image_vol_id}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings   ${response_json['status']}  ${attach_status}

List server boot from image
    Should Be Equal As Strings  ${PREV TEST STATUS}     PASS    Not list server if create server failed
    [Documentation]   List server boot from image
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/servers?name=${server_name_image}   # Server list
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    ${respDataLength}    Get Length    ${response_json['servers']}
    Should Be True    ${respDataLength} >= 1

Duplicate Create server boot from image
    Should Be Equal As Strings  ${PREV TEST STATUS}     PASS    Not create server if server list failed
    [Documentation]   Create duplicate server boot from image
    ${boot}    Create Dictionary    type=2    imageId=${image_id}
    ${portid}    Create Dictionary    portId=${port_id_1}
    ${nic_array}    Create List   ${portid}

    ${body}    Create Dictionary    name=${server_name_image}    boot=${boot}    flavorId=${flavor_id}    nicArray=${nic_array}
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/servers    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Integers   ${response_json['returnCode']}   0
    Should Be Equal As Strings    ${server_image_id}    ${response_json['id']}

Delete server boot from image
    [Documentation]   Delete server boot from image
    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/servers/${server_image_id}   # Server delete
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}
    Sleep  20s  # Wait for task complete
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/servers/${server_image_id}
    Should Be Equal As Integers   ${resp.status_code}   ${invalid_status}

Volume create
    [Documentation]   Create volume
    ${body}    Create Dictionary    name=${vol_name}    volumeSize=${vol_size}    imageId=${image_id}
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/volumes    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${vol_id}    ${response_json['id']}

    Sleep  90s    # Waiting for volume create done
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/volumes/${vol_id}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings   ${response_json['status']}  ${vol_status}

Create server boot from volume
    Should Be Equal As Strings  ${PREV TEST STATUS}     PASS    Not boot server from volume if create volume failed
    [Documentation]   Create server boot from volume
    ${boot}    Create Dictionary    type=1    volumeId=${vol_id}
    ${portid}  Create Dictionary    portId=${port_id_2}
    ${nic_array}   Create List   ${portid}

    ${body}    Create Dictionary    name=${server_name_vol}    boot=${boot}    flavorId=${flavor_id}    nicArray=${nic_array}
    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/servers    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${accept_status}
    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Integers   ${response_json['returnCode']}   1
    Set Suite Variable    ${server_volume_id}    ${response_json['id']}

    Sleep  90s   # Waiting for server create done
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/servers/${server_volume_id}  # Server get
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings   ${response_json['status']}  ${server_status}

List server boot from volume
    Should Be Equal As Strings  ${PREV TEST STATUS}     PASS    Not list server if create server failed
    [Documentation]   List server boot from volume
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/servers?name=${server_name_vol}  # Server list
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}
    ${response_json}    json.loads    ${resp.content}
    ${respDataLength}    Get Length    ${response_json['servers']}
    Should Be True    ${respDataLength} >= 1

Delete server boot from volume
    Should Be Equal As Strings  ${PREV TEST STATUS}     PASS    Not delete server if list server failed
    [Documentation]   Delete server boot from volume
    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/servers/${server_volume_id}  # Server delete
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}
    Sleep  20s  # Wait for task complete
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/servers/${server_volume_id}
    Should Be Equal As Integers   ${resp.status_code}   ${invalid_status}

Clean up flavor
    [Documentation]   Clean up flavor
    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/flavors/${flavor_id}
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}

Clean up network, subnet and port
    [Documentation]   Clean up network, subnet, port
    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/ports/${port_id_1}
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}

    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/ports/${port_id_2}
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}

    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/subnets/${subnet_id}
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}

    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/networks/${net_id}
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}

Clean up volume
    [Documentation]   Clean up volume
    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/volumes/${vol_id}
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}

    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/volumes/${image_vol_id}
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}
