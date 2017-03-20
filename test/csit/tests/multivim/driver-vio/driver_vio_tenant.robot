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

${success_status}   200

*** Test Cases ***
Get vio vim
    ${headers}    Create Dictionary    Content-Type=application/json    Accept=application/json
    Create Session    msb_session    http://${MSB_ADDR}    headers=${headers}
    ${resp}=  Get Request    msb_session    ${extsys_path}/vims
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${vim_id}    ${response_json[0]['vimId']}

Tenant get test
    [Documentation]   Tenant get list test
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/tenants
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings    ${response_json['vimId']}    ${vim_id}
    ${respDataLength}    Get Length    ${response_json['tenants']}
    Should Be True    ${respDataLength} > 0
