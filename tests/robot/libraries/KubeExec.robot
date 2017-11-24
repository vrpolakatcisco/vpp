*** Settings ***
Documentation     This is a library for interacting with containers inside pods by "docker exec" on appropriate host.
...
...               Two approaches are supported. Either direct command execution,
...               or opening interactive bash (for ShellOverSsh).
Resource          ${CURDIR}/all_libs.robot

*** Keywords ***
Open_Parallel_Host_Connection
    [Arguments]    ${new_alias}    ${user}=${KUBE_DEFAULT_USER}    ${passwd}=${KUBE_DEFAULT_PASSWD}
    [Documentation]    Open another SSH connection to currently active host with given alias.
    ...    Note that this puts the previously active SSH connection to background, so rember to switch later.
    BuiltIn.Log_Many    ${new_alias}    ${user}    ${passwd}
    # TODO: SshCommons.Fork_Active_Connection? NamedVms.New_Connection_For_Index?
    ${current_conenction} =    SSHLibrary.Get_Conection
    SshCommons.Open_Ssh_Connection    ${new_alias}    ${current_connection.host}    ${user}    ${passwd}

Open_New_Bash_Container_Connection
    [Arguments]    ${new_alias}    ${pod_name}    ${user}=${KUBE_DEFAULT_USER}    ${passwd}=${KUBE_DEFAULT_PASSWD}
    [Documentation]    Open another SSH connection assuming active session points to correct host, configure prompt,
    ...    execute interactive bash first container of \${pod_name}, read until prompt, log and return output.
    ...    Note that this puts the previously active SSH connection to background, so rember to switch later.
    BuiltIn.Log_Many    ${new_alias}    ${pod_name}    ${prompt}    ${user}    ${passwd}
    Open_Parallel_Host_Connection    ${new_alias}    ${user}    ${passwd}
    ${docker} =    NamedVms.Get_Host_Docker
    SSHLibrary.Set_Client_Configuration    prompt=\#
    SSHLibrary.Write    ${docker} exec -it --privileged ${pod_name}  /bin/bash
    ${output} =     SSHLibrary.Read_Until_Prompt
    Log     ${output}
    [Return]    ${output}

Close_Active_Container_Connection
    [Arguments]     ${prompt}=\$
    [Documentation]    Configure prompt, send ctrl+c, write "exit", read until prompt, close connection, log and return output.
    ...    Note that this leaves the SSHLibrary in a state where all connections are background, so swith later.
    BuiltIn.Log_Many    ${prompt}
    SSHLibrary.Set_Client_Configuration    prompt=${prompt}
    SshCommons.Write_Bare_Ctrl_C
    SSHLibrary.Write    exit
    ${output} =     SSHLibrary.Read_Until_Prompt
    Log     ${output}
    SSHLibrary.Close_Connection
    [Return]    ${output}

Execute_In_Container
    [Arguments]    ${pod_name}    ${command}    ${container}=${EMPTY}    ${tty}=${False}    ${stdin}=${False}    ${ignore_stderr}=${False}    ${ignore_rc}=${False}
    [Documentation]    Execute "docker exec" with given command and parameters on active connection, return the result.
    Builtin.Log_Many    ${pod_name}    ${command}    ${container}    ${tty}    ${stdin}    ${ignore_stderr}    ${ignore_rc}
    ${docker} =    NamedVms.Get_Host_Docker
    ${space_c} =    BuiltIn.Set_Variable_If    """${container}"""    ${SPACE}-c ${container}    ${EMPTY}
    ${space_t} =    BuiltIn.Set_Variable_If    ${tty}    ${SPACE}-t    ${EMPTY}
    ${space_i} =    BuiltIn.Set_Variable_If    ${stdin}    ${SPACE}-i    ${EMPTY}
    BuiltIn.Run_Keyword_And_Return    SshCommons.Execute_Command_And_Log    kubectl exec ${pod_name}${space_c}${space_t}${space_i} -- ${command}    ignore_stderr=${ignore_stderr}    ignore_rc=${ignore_rc}
