*** Settings ***
Documentation     This is a library for manipulating shells over SSH existing connections.
Library           SSHLibrary
Resource          ${CURDIR}/NamedVms.robot
Resource          ${CURDIR}/SshCommons.robot

*** Keywords ***
Start_Command_In_Active_Conection
    [Arguments]    ${command}    ${prompt}=${EMPTY}
    [Documentation]    Configure if \${prompt}, write \${command}.
    BuiltIn.Log_Many    ${command}    ${prompt}
    BuiltIn.Run_Keyword_If    """${prompt}"""    SSHLibrary.Set_Client_Configuration    prompt=${prompt}
    SSHLibrary.Write    ${command}

Switch_And_Start_Command
    [Arguments]    ${alias}    ${command}    ${prompt}=${EMPTY}
    [Documentation]    Switch to ${alias}, proceed with Start_Command_In_Active_Conection.
    BuiltIn.Log_Many    ${alias}    ${command}    ${prompt}=${EMPTY}
    SSHLibrary.Switch_Connection    ${alias}
    BuiltIn.Run_Keyword_And_Return    Start_Command_In_Active_Conection    ${command}    ${prompt}

Switch_To_Index_And_Start_Command
    [Arguments]    ${index}    ${command}    ${prompt}=${EMPTY}
    [Documentation]    Switch to node for index, proceed with Start_Command_In_Active_Conection.
    BuiltIn.Log_Many    ${index}    ${command}    ${prompt}
    NamedVms.Switch_To_Node_For_Index    ${index}
    BuiltIn.Run_Keyword_And_Return    Start_Command_In_Active_Conection    ${command}    ${prompt}

Read_Command_Output_From_Active_Conection
    [Documentation]    Read until prompt, log and return output.
    ${output} =    SSHLibrary.Read_Until_Prompt
    Log     ${output}
    [Return]    ${output}

Stop_Command_In_Active_Conection
    [Documentation]    Sent ctrl+c and proceed with Read_Command_Output_From_Active_Conection.
    SshCommons.Write_Bare_Ctrl_C
    BuiltIn.Run_Keyword_And_Return    Read_Command_Output_From_Active_Conection

Switch_And_Stop_Command
    [Arguments]    ${alias}
    [Documentation]    Switch to ${alias}, proceed with Stop_Command_In_Active_Conection.
    SSHLibrary.Switch_Connection    ${alias}
    BuiltIn.Run_Keyword_And_Return    Stop_Command_In_Active_Conection

Switch_To_Index_And_Stop_Command
    [Arguments]    ${index}
    [Documentation]    Switch to node for index, proceed with Stop_Command_In_Active_Conection.
    BuiltIn.Log_Many    ${index}
    NamedVms.Switch_To_Node_For_Index    ${index}
    BuiltIn.Run_Keyword_And_Return    Stop_Command_In_Active_Conection

Execute_Command_In_Active_Conection
    [Arguments]    ${command}    ${prompt}=${EMPTY}
    [Documentation]    Configure if \${prompt}, write \${command}, read until prompt, log and return text output.
    Start_Command_In_Active_Conection    ${command}    ${prompt}
    Builtin.Run_Keyword_And_Return    Read_Command_Output_From_Active_Conection

Switch_And_Execute_Command
    [Arguments]    ${alias}    ${command}    ${prompt}=${EMPTY}
    [Documentation]    Switch to ${alias}, proceed with Execute_Command_In_Active_Conection.
    BuiltIn.Log_Many    ${alias}    ${command}    ${prompt}=${EMPTY}
    SSHLibrary.Switch_Connection    ${alias}
    BuiltIn.Run_Keyword_And_Return    Execute_Command_In_Active_Conection    ${command}    ${prompt}

# TODO: Switch_To_Index_And_Execute_Command makes sense, or is NamedVms.Switch_To_Node_And_Execute_Command better?
