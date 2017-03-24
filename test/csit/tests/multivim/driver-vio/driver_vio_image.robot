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
${image_type}   vmdk
${image_status}   active
${image_visibility}   public
${image_container}   bare

${new_image_path}   http://partnerweb.vmware.com/programs/vmdkimage/cirros-0.3.0-i386.vmdk
${new_image_name}   cirros

*** Test Cases ***
Get vio vim
    ${headers}    Create Dictionary    Content-Type=application/json    Accept=application/json
    Create Session    msb_session    http://${MSB_ADDR}    headers=${headers}
    ${resp}=  Get Request    msb_session    ${extsys_path}/vims
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${vim_id}    ${response_json[0]['vimId']}

Image list test
    [Documentation]   Image list test
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/tenants?name=${admin}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    Set Suite Variable    ${tenant_id}    ${response_json['tenants'][0]['id']}

    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings    ${response_json['tenantId']}   ${tenant_id}
    Should Be Equal As Strings    ${response_json['vimId']}    ${vim_id}
    Should Be Equal As Strings    ${response_json['images'][0]['name']}   ${image_name}

    Set Suite Variable    ${image_id}    ${response_json['images'][0]['id']}

Image get test
    [Documentation]   Image get test
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images/${image_id}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings    ${response_json['tenantId']}   ${tenant_id}
    Should Be Equal As Strings    ${response_json['vimId']}    ${vim_id}
    Should Be Equal As Strings    ${response_json['name']}   ${image_name}
    Should Be Equal As Strings    ${response_json['imageType']}   ${image_type}
    Should Be Equal As Strings    ${response_json['status']}   ${image_status}
    Should Be Equal As Strings    ${response_json['visibility']}   ${image_visibility}
    Should Be Equal As Strings    ${response_json['containerFormat']}   ${image_container}

Image create test
    [Documentation]   Image create test
    ${body}    Create Dictionary    imagePath=${new_image_path}    visibility=${image_visibility}    name=${new_image_name}
    ...    imageType=${image_type}   containerFormat=${image_container}

    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${accept_status}

    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Integers   ${response_json['returnCode']}   1
    Should Be Equal As Strings    ${response_json['tenantId']}   ${tenant_id}
    Should Be Equal As Strings    ${response_json['vimId']}    ${vim_id}
    Should Be Equal As Strings    ${response_json['name']}   ${new_image_name}
    Should Be Equal As Strings    ${response_json['imageType']}   ${image_type}
    Should Be Equal As Strings    ${response_json['visibility']}   ${image_visibility}
    Should Be Equal As Strings    ${response_json['containerFormat']}   ${image_container}

    Set Suite Variable    ${new_image_id}    ${response_json['id']}
    Sleep  90s    # Waiting for image create done
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images/${new_image_id}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Strings    ${response_json['status']}   ${image_status}
    Should Be Equal As Strings    ${response_json['name']}   ${new_image_name}

    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images?name=${new_image_name}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    ${respDataLength}    Get Length    ${response_json['images']}
    Should Be Equal As Integers    ${respDataLength}   1

Duplicate Image create test
    [Documentation]   Duplicate Image create test
    ${body}    Create Dictionary    imagePath=${new_image_path}    visibility=${image_visibility}    name=${new_image_name}
    ...    imageType=${image_type}   containerFormat=${image_container}

    ${resp}=  Post Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images    ${body}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    Should Be Equal As Integers   ${response_json['returnCode']}   0
    Should Be Equal As Strings    ${response_json['id']}   ${new_image_id}

    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images?name=${new_image_name}
    Should Be Equal As Integers   ${resp.status_code}   ${success_status}

    ${response_json}    json.loads    ${resp.content}
    ${respDataLength}    Get Length    ${response_json['images']}
    Should Be Equal As Integers    ${respDataLength}   1

Image delete test
    [Documentation]   Image delete test
    ${resp}=  Delete Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images/${new_image_id}
    Should Be Equal As Integers   ${resp.status_code}   ${delete_status}

    Sleep  20s    # Waiting for image delete done
    ${resp}=  Get Request    msb_session    ${multivim_path}/${vim_id}/${tenant_id}/images/${new_image_id}
    Should Be Equal As Integers   ${resp.status_code}   ${invalid_status}
