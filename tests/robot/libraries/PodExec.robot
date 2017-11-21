*** Settings ***
Documentation     This is a library to handle commands to be run inside pod.
...
...               Some keywords assume an SSH connection to a relevant host is active,
...               other keywords assume the active SSH conenction points to separate bash in pod.
Library           SSHLibrary
Resource          ${CURDIR}/KubeCtl.robot
Resource          ${CURDIR}/SshCommons.robot

*** Keywords ***
Open_New_Bash_Container_Session
    [Arguments]    ${new_alias}    ${pod_name}    ${prompt}=${EMPTY}    ${user}=${KUBE_DEFAULT_USER}    ${passwd}=${KUBE_DEFAULT_PASSWD}
    [Documentation]    Open another SSH session to currently active host, configure if prompt,
    ...    execute interactive bash in ${pod_name}, read until prompt, log and return output.
    ...    Note that this puts the previously active SSH session to background, so rember to switch later.
    BuiltIn.Log_Many    ${new_alias}    ${pod_name}    ${prompt}    ${user}    ${passwd}
    # TODO: SshCommons.Fork_Active_Connection? NamedVms.New_Connection_For_Index?
    ${current_conenction} =    SSHLibrary.Get_Conection
    SshCommons.Open_Ssh_Connection    ${new_alias}    ${current_connection.host}    ${user}    ${passwd}
    BuiltIn.Run_Keyword_If    """${prompt}""" != """${EMPTY}"""    SSHLibrary.Set_Client_Configuration    prompt=${prompt}
    SSHLibrary.Write    kubectl exec -it ${pod_name} -- /bin/bash
    ${output} =     SSHLibrary.Read_Until_Prompt
    Log     ${output}
    [Return]    ${output}

Close_Active_Container_Session
    [Arguments]     ${prompt}=\$
    [Documentation]    Configure prompt, send ctrl+c, write "exit", read until prompt, close session, log and return output.
    ...    Note that this leaves the SSHLibrary in a state where all connections are background, so swith later.
    BuiltIn.Log_Many    ${prompt}
    SSHLibrary.Set_Client_Configuration    prompt=${prompt}
    Write_Bare_Ctrl_C
    SSHLibrary.Write    exit
    ${output} =     SSHLibrary.Read_Until_Prompt
    Log     ${output}
    SSHLibrary.Close_Connection
    [Return]    ${output}

Start_Command_In_Active_Container_Session
    [Arguments]    ${command}    ${prompt}=${EMPTY}
    [Documentation]    Configure if \${prompt}, write \${command}.
    BuiltIn.Log_Many    ${command}    ${prompt}
    BuiltIn.Run_Keyword_If    """${prompt}"""    SSHLibrary.Set_Client_Configuration    prompt=${prompt}
    SSHLibrary.Write    ${command}

Read_Command_Output_From_Active_Container_Session
    [Documentation]    Read until prompt, log and return output.
    ${output} =     SSHLibrary.Read_Until_Prompt
    Log     ${output}
    [Return]    ${output}

Stop_Command_In_Active_Container_Session
    [Documentation]    Sent ctrl+c and proceed with Read_Command_Output_From_Active_Container_Session.
    SshCommons.Write_Bare_Ctrl_C
    BuiltIn.Run_Keyword_And_Return    Read_Command_Output_From_Active_Container_Session

Execute_Command_In_Active_Container_Session
    [Arguments]    ${command}    ${prompt}=${EMPTY}
    [Documentation]    Configure if \${prompt}, write \${command}, read until prompt, log and return text output.
    Start_Command_In_Active_Container_Session    ${command}    ${prompt}
    Builtin.Run_Keyword_And_Return    Read_Command_Output_From_Active_Container_Session
