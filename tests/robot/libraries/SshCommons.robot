*** Settings ***
Documentation     This is a library for simple improvements over SSHLibrary for other robot libraries to use.
Library    SSHLibrary

*** Keywords ***
Switch_And_Execute_With_Copied_File
    [Arguments]    ${ssh_session}    ${file_path}    ${command_prefix}    ${expected_rc}=0    ${ignore_stderr}=${False}
    [Documentation]    Switch to \${ssh_session} and continue with Execute_Command_With_Copied_File.
    BuiltIn.Log_Many    ${ssh_session}    ${file_path}    ${command_prefix}    ${expected_rc}    ${ignore_stderr}
    SSHLibrary.Switch_Connection    ${ssh_session}
    BuiltIn.Run_Keyword_And_Return    Execute_Command_With_Copied_File    ${command_prefix}    expected_rc=${expected_rc}    ignore_stderr=${ignore_stderr}

Execute_Command_With_Copied_File
    [Arguments]    ${file_path}    ${command_prefix}    ${expected_rc}=0    ${ignore_stderr}=${False}
    [Documentation]    Put file to current remote directory and execute command which takes computed file name as argument.
    BuiltIn.Log_Many    ${file_path}    ${command_prefix}    ${expected_rc}    ${ignore_stderr}
    Builtin.Comment    TODO: Do not pollute current remote directory. See https://github.com/contiv/vpp/issues/195
    SSHLibrary.Put_File    ${file_path}    .
    ${splitted_path} =    String.Split_String    ${file_path}    separator=${/}
    BuiltIn.Run_Keyword_And_Return    Execute_Command_And_Log    ${command_prefix} @{splitted_path}[-1]    expected_rc=${expected_rc}    ignore_stderr=${ignore_stderr}

Switch_And_Execute_Command
    [Arguments]    ${ssh_session}    ${command}    ${expected_rc}=0    ${ignore_stderr}=${False}
    [Documentation]    Switch to \${ssh_session}, and continue with Execute_Command_And_Log.
    BuiltIn.Log_Many    ${ssh_session}    ${command}    ${expected_rc}    ${ignore_stderr}
    SSHLibrary.Switch_Connection    ${ssh_session}
    BuiltIn.Run_Keyword_And_Return    Execute_Command_And_Log    ${command}    expected_rc=${expected_rc}    ignore_stderr=${ignore_stderr}

Execute_Command_And_Log
    [Arguments]    ${command}    ${expected_rc}=0    ${ignore_stderr}=${False}
    [Documentation]    Execute \${command} on current SSH session, log results, maybe fail on nonempty stderr, check \${expected_rc}, return stdout.
    BuiltIn.Log_Many    ${command}    ${expected_rc}    ${ignore_stderr}
    BuiltIn.Comment    TODO: Add logging to file. See https://github.com/contiv/vpp/issues/200
    ${stdout}    ${stderr}    ${rc} =    SSHLibrary.Execute_Command    ${command}    return_stderr=True    return_rc=True
    BuiltIn.Log    ${stdout}
    BuiltIn.Log    ${stderr}
    BuiltIn.Log    ${rc}
    BuiltIn.Run_Keyword_Unless    ${ignore_stderr}    BuiltIn.Should_Be_Empty    ${stderr}
    BuiltIn.Should_Be_Equal_As_Numbers    ${rc}    ${expected_rc}
    [Return]    ${stdout}
