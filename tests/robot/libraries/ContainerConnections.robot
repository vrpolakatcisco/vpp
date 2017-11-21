*** Settings ***
Documentation     This is a library to handle SSH connections to containers inside pods.
...
...               Keywords for running commands over the connections are elsewhere.
Library           SSHLibrary
Resource          ${CURDIR}/KubeCtl.robot
Resource          ${CURDIR}/SshCommons.robot

*** Keywords ***
Open_New_Bash_Container_Connection
    [Arguments]    ${new_alias}    ${pod_name}    ${prompt}=${EMPTY}    ${user}=${KUBE_DEFAULT_USER}    ${passwd}=${KUBE_DEFAULT_PASSWD}
    [Documentation]    Open another SSH connection to currently active host, configure if prompt,
    ...    execute interactive bash in ${pod_name}, read until prompt, log and return output.
    ...    Note that this puts the previously active SSH connection to background, so rember to switch later.
    BuiltIn.Log_Many    ${new_alias}    ${pod_name}    ${prompt}    ${user}    ${passwd}
    # TODO: SshCommons.Fork_Active_Connection? NamedVms.New_Connection_For_Index?
    ${current_conenction} =    SSHLibrary.Get_Conection
    SshCommons.Open_Ssh_Connection    ${new_alias}    ${current_connection.host}    ${user}    ${passwd}
    BuiltIn.Run_Keyword_If    """${prompt}""" != """${EMPTY}"""    SSHLibrary.Set_Client_Configuration    prompt=${prompt}
    SSHLibrary.Write    kubectl exec -it ${pod_name} -- /bin/bash
    ${output} =     SSHLibrary.Read_Until_Prompt
    Log     ${output}
    [Return]    ${output}

Close_Active_Container_Connection
    [Arguments]     ${prompt}=\$
    [Documentation]    Configure prompt, send ctrl+c, write "exit", read until prompt, close connection, log and return output.
    ...    Note that this leaves the SSHLibrary in a state where all connections are background, so swith later.
    BuiltIn.Log_Many    ${prompt}
    SSHLibrary.Set_Client_Configuration    prompt=${prompt}
    Write_Bare_Ctrl_C
    SSHLibrary.Write    exit
    ${output} =     SSHLibrary.Read_Until_Prompt
    Log     ${output}
    SSHLibrary.Close_Connection
    [Return]    ${output}
