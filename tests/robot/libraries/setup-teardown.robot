*** Settings ***
Documentation     Keywords for testsuite setup and teardown.
...
...               Each suite should depend on this, so that some settings are centralized here,
...               mainly concerning lab environment details.
...
...               Currently lab details are hardwired in robot files.
...               Several setups are available, users can chose by overriding
...               \${ENV} (or also \${VARIABLES}).
...
...               TODO: Describe \${snapshot_num} (or remove it).
Library           OperatingSystem
Library           SSHLibrary
Resource          ${CURDIR}/NamedVms.robot
#Resource          ${CURDIR}/SshCommons.robot
Resource          ${CURDIR}/${ENV}_setup-teardown.robot
Resource          ${CURDIR}/../variables/${VARIABLES}_variables.robot

*** Variables ***
${ENV}            common
${VARIABLES}      ${ENV}
${snapshot_num}    0

*** Keywords ***
Testsuite_Setup
    [Documentation]    Perform actions common for setup of every suite.
    ...    FIXME: Improve this Documentation.
    Discard_Old_Results
    NamedVms.Create_Connections_To_Kube_Cluster
    ${master_ip} =    NamedVms.Get_Host_Ip_For_Index    1
    BuiltIn.Set_Suite_Variable    \${master_ip}
    ${master_alias} =    NamedVms.Get_Host_Alias_For_Index    1
    BuiltIn.Set_Suite_Variable    \${master_alias}

Testsuite_Teardown
    [Documentation]    Perform actions common for teardown of every suite.
    NamedVms.Log_All_SSH_Outputs
    SSHLibrary.Get_Connections
    SSHLibrary.Close_All_Connections

Discard_Old_Results
    [Documentation]    Remove and re-create ${RESULTS_FOLDER}.
    OperatingSystem.Remove_Directory    ${RESULTS_FOLDER}    recursive=True
    OperatingSystem.Create_Directory    ${RESULTS_FOLDER}

Make_Datastore_Snapshots
    [Arguments]    ${tag}=notag
    [Documentation]    Log ${tag}, compute next prefix (and do nothing with it).
    BuiltIn.Log_Many    ${tag}
    ${prefix} =    Create_Next_Snapshot_Prefix

Create_Next_Snapshot_Prefix
    [Documentation]    Contruct new prefix, store next snapshot num. Return the prefix.
    ${prefix} =    BuiltIn.Evaluate    str(${snapshot_num}).zfill(2)
    ${snapshot_num} =    BuiltIn.Evaluate    ${snapshot_num}+1
    BuiltIn.Set_Global_Variable    ${snapshot_num}
    [Return]    ${prefix}
