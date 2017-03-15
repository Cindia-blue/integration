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
${admin}   admin
${image_name}   ubuntu-14.04-server-amd64
${image_type}   vmdk
${image_status}   active
${image_visibility}   public
${image_container}   bare

*** Test Cases ***
Get vio vim
    ${headers}    Create Dictionary    Content-Type=application/json    Accept=application/json
    Create Session    msb_session    http://${MSB_ADDR}    headers=${headers}
    ${resp}=  Get Request    msb_session    ${extsys_path}/vims
    Should Be Equal As Integers   ${resp.status_code}  200

    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${vim_id}    ${response_json[0]['vimId']}

Image list test
    [Documentation]   Image list test
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/tenants
    Should Be Equal As Integers   ${resp.status_code}  200

    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings    ${response_json['tenants'][0]['name']}   ${admin}
    Set Suite Variable    ${tenant_id}    ${response_json['tenants'][0]['id']}

    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images
    Should Be Equal As Integers   ${resp.status_code}  200

    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings    ${response_json['tenantId']}   ${tenant_id}
    Should Be Equal As Strings    ${response_json['vimId']}    ${vim_id}
    Should Be Equal As Strings    ${response_json['images'][0]['name']}   ${image_name}

    Set Suite Variable    ${image_id}    ${response_json['images'][0]['id']}

Image get test
    [Documentation]   Image get test
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images/${image_id}
    Should Be Equal As Integers   ${resp.status_code}  200

    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings    ${response_json['tenantId']}   ${tenant_id}
    Should Be Equal As Strings    ${response_json['vimId']}    ${vim_id}
    Should Be Equal As Strings    ${response_json['name']}   ${image_name}
    Should Be Equal As Strings    ${response_json['imageType']}   ${image_type}
    Should Be Equal As Strings    ${response_json['status']}   ${image_status}
    Should Be Equal As Strings    ${response_json['visibility']}   ${image_visibility}
    Should Be Equal As Strings    ${response_json['containerFormat']}   ${image_container}