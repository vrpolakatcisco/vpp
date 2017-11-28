*** Settings ***
Documentation     This is a library for simple improvements over SSHLibrary for other robot libraries to use.
Resource          ${CURDIR}/all_libs.robot

*** Keywords ***
Write_Bare_Ctrl_C
    [Documentation]    Construct ctrl+c character and SSH-write it (without endline) to the current SSH connection.
    ...    Do not read anything yet.
    ${ctrl_c} =    BuiltIn.Evaluate    chr(int(3))
    SSHLibrary.Write_Bare    ${ctrl_c}

Restore_Current_Ssh_Connection_From_Index
    [Arguments]    ${connection_index}
    [Documentation]    Restore active SSH connection in SSHLibrary to given index.
    ...
    ...    Restore the currently active connection state in
    ...    SSHLibrary to match the state returned by "Switch
    ...    Connection" or "Get Connection". More specifically makes
    ...    sure that there will be no active connection when the
    ...    \${connection_index} reported by these means is None.
    ...
    ...    There is a misfeature in SSHLibrary: Invoking "SSHLibrary.Switch_Connection"
    ...    and passing None as the "index_or_alias" argument to it has exactly the
    ...    same effect as invoking "Close Connection".
    ...    https://github.com/robotframework/SSHLibrary/blob/master/src/SSHLibrary/library.py#L560
    ...
    ...    We want to have Keyword which will "switch out" to previous
    ...    "no connection active" state without killing the background one.
    ...
    ...    As some suites may hypothetically rely on non-writability of active connection,
    ...    workaround is applied by opening and closing temporary connection.
    ...    Unfortunately this will fail if run on Jython and there is no SSH server
    ...    running on localhost, port 22 but there is nothing easy that can be done about it.
    BuiltIn.Run Keyword And Return If    ${connection_index} is not None    SSHLibrary.Switch Connection    ${connection_index}
    # The background connection is still current, bury it.
    SSHLibrary.Open Connection    127.0.0.1
    SSHLibrary.Close Connection

Run_Keyword_Preserve_Connection
    [Arguments]    ${keyword_name}    @{args}    &{kwargs}
    [Documentation]    Store current connection index, run keyword returning its result, restore connection in teardown.
    ...    Note that in order to avoid "got positional argument after named arguments",
    ...    it is safer to use positional (not named) arguments on call.
    ${current_connection} =    SSHLibrary.Get_Connection
    BuiltIn.Run_Keyword_And_Return    ${keyword_name}    @{args}    &{kwargs}
    [Teardown]    Restore_Current_SSH_Connection_From_Index    ${current_connection.index}

Open_Ssh_Connection
    [Arguments]    ${name}    ${ip}    ${user}=${KUBE_DEFAULT_USER}    ${psswd}=${KUBE_DEFAULT_PASSWD}
    [Documentation]    Create SSH connection to \{ip} aliased as \${name} and log in using \${user} and \${pswd} (or rsa).
    ...    Log to output file. The new connection is left active.
    BuiltIn.Log_Many    ${name}    ${ip}    ${user}    ${pswd}
    SSHLibrary.Open_Connection    ${ip}    alias=${name}    timeout=${SSH_TIMEOUT}
    ${out} =    BuiltIn.Run_Keyword_If    """${pswd}""" != "rsa_id"    SSHLibrary.Login    ${user}    ${pswd}
    ${out2} =    BuiltIn.Run_Keyword_If    """${pswd}""" == "rsa_id"    SSHLibrary.Login_With_Public_Key    ${user}    %{HOME}/.ssh/id_rsa    any
    BuiltIn.Run_Keyword_If    """${out}""" != "None"    OperatingSystem.Append_To_File    ${RESULTS_FOLDER}/output_${name}.log    *** Command: Login${\n}${out}${\n}
    BuiltIn.Run_Keyword_If    """${out2}""" != "None"    OperatingSystem.Append_To_File    ${RESULTS_FOLDER}/output_${name}.log    *** Command: Login${\n}${out2}${\n}

Execute_Command_And_Log
    [Arguments]    ${command}    ${expected_rc}=0    ${ignore_stderr}=${False}    ${ignore_rc}=${False}
    [Documentation]    Execute \${command} on current SSH session in parallel bash, log results,
    ...    optionally fail on nonempty stderr, optionally check \${expected_rc}, return stdout.
    ...    "In parallel bash" means you need other keyword to run command in nested bash (e.g. created by docker exec).
    BuiltIn.Log_Many    ${command}    ${expected_rc}    ${ignore_stderr}    ${ignore_rc}
    ${stdout}    ${stderr}    ${rc} =    SSHLibrary.Execute_Command    ${command}    return_stderr=True    return_rc=True
    Append_Command_Log    ${command}    ${stdout}    ${stderr}    ${rc}
    BuiltIn.Run_Keyword_Unless    ${ignore_stderr}    BuiltIn.Should_Be_Empty    ${stderr}
    BuiltIn.Run_Keyword_Unless    ${ignore_rc}    BuiltIn.Should_Be_Equal_As_Numbers    ${rc}    ${expected_rc}
    [Return]    ${stdout}

Switch_And_Execute_Command
    [Arguments]    ${alias}    ${command}    ${expected_rc}=0    ${ignore_stderr}=${False}    ${ignore_rc}=${False}    ${log_stdout}=${True}
    [Documentation]    Switch to \${alias}, proceed with Execute_Command_And_Log.
    BuiltIn.Log_Many    ${alias}    ${command}    ${expected_rc}    ${ignore_stderr}    ${ignore_rc}    ${log_stdout}
    SSHLibrary.Switch_Connection    ${alias}
    BuiltIn.Run_Keyword_And_Return    Execute_Command_And_Log    ${command}    ${expected_rc}    ${ignore_stderr}    ${ignore_rc}    ${log_stdout}

Switch_To_Node_And_Execute_Command
    [Arguments]    ${index}    ${command}    ${expected_rc}=0    ${ignore_stderr}=${False}    ${ignore_rc}=${False}    ${log_stdout}=${True}
    [Documentation]    Switch host node given by \${index}, proceed with Execute_Command_And_Log.
    BuiltIn.Log_Many    ${index}    ${command}    ${expected_rc}    ${ignore_stderr}    ${ignore_rc}    ${log_stdout}
    NamedVms.Shitch_To_Node_For_Index    ${index}
    BuiltIn.Run_Keyword_And_Return    Execute_Command_And_Log    ${command}    ${expected_rc}    ${ignore_stderr}    ${ignore_rc}    ${log_stdout}

Execute_Command_With_Copied_File
    [Arguments]    ${command_prefix}    ${file_path}    ${expected_rc}=0    ${ignore_stderr}=${False}
    [Documentation]    Put file to current remote directory and execute command which takes computed file name as argument.
    BuiltIn.Log_Many    ${file_path}    ${command_prefix}    ${expected_rc}    ${ignore_stderr}
    Builtin.Comment    TODO: Do not pollute current remote directory. See https://github.com/contiv/vpp/issues/195
    SSHLibrary.Put_File    ${file_path}    .
    ${splitted_path} =    String.Split_String    ${file_path}    separator=${/}
    BuiltIn.Run_Keyword_And_Return    Execute_Command_And_Log    ${command_prefix} @{splitted_path}[-1]    expected_rc=${expected_rc}    ignore_stderr=${ignore_stderr}

Switch_Execute_And_Log_To_File
    [Arguments]    ${alias}    ${command}    ${expected_rc}=0    ${ignore_stderr}=${False}    ${ignore_rc}=${False}    ${compress}=${False}
    [Documentation]    Call Switch_And_Execute_Command redirecting stdout to a remote file, download the file.
    ...    To distinguish separate invocations, suite name, test name, session alias
    ...    and full command are used to construct file name.
    BuiltIn.Log_Many    ${alias}    ${command}    ${expected_rc}    ${ignore_stderr}    ${ignore_rc}    ${compress}
    SSHLibrary.Switch_Connection    ${alias}
    ${connection} =    SSHLibrary.Get_Connection
    # In teardown, ${TEST_NAME} does not exist.
    ${testname} =    BuiltIn.Get_Variable_Value    ${TEST_NAME}    ${EMPTY}
    ${filename_with_spaces} =    BuiltIn.Set_Variable    ${testname}__${SUITE_NAME}__${connection.alias}__${command}.log
    ${filename} =    String.Replace_String    ${filename_with_spaces}    ${SPACE}    _
    BuiltIn.Log    ${filename}
    Execute_Command_And_Log    ${command} > ${filename}    expected_rc=${expected_rc}    ignore_stderr=${ignore_stderr}    ignore_rc=${ignore_rc}
    BuiltIn.Run_Keyword_If    ${compress}    Execute_Command_And_Log    xz -9e ${filename}
    ${filename} =    Builtin.Set_Variable_If    ${compress}    ${filename}.xz    ${filename}
    SSHLibrary.Get_File    ${filename}    ${RESULTS_FOLDER}/${filename}
    [Teardown]    Execute_Command_And_Log    rm ${filename}

Switch_And_Write_Command
    [Arguments]    ${ssh_session}    ${command}    ${prompt}=vpp#
    [Documentation]    Switch to \${ssh_session}, and continue with Write_Command_And_Log
    BuiltIn.Log_Many    ${ssh_session}    ${command}    ${prompt}
    SSHLibrary.Switch_Connection    ${ssh_session}
    BuiltIn.Run_Keyword_And_Return    Write_Command_And_Log    ${command}    ${prompt}

Write_Command_And_Log
    [Arguments]    ${command}    ${prompt}=vpp#
    [Documentation]    Write \${command} on current SSH session, wait for prompt, log output, return output.
    BuiltIn.Log_Many    ${command}    ${prompt}
    SSHLibrary.Write    ${command}
    ${output} =    SSHLibrary.Read_Until    ${prompt}
    Append_Command_Log    ${command}    ${output}
    [Return]    ${output}

Append_Command_Log
    [Arguments]    ${command}    ${output}=${EMPTY}    ${stderr}=${EMPTY}    ${rc}=${EMPTY}
    [Documentation]    Detect connection alias and time, append line with command and output to appropriate log file.
    Builtin.Log_Many    ${command}    ${output}    ${stderr}    ${rc}
    ${connection} =    SSHLibrary.Get_Connection
    ${time} =    DateTime.Get_Current_Date
    ${output_length} =    BuiltIn.Get_Length    ${output}
    ${if_output} =    BuiltIn.Set_Variable_If    ${output_length}    ${output}${\n}    ${EMPTY}
    ${stderr_length} =    Builtin.Get_Length    ${stderr}
    ${if_stderr} =    BuiltIn.Set_Variable_If    ${stderr_length}    *** Stderr: ${stderr}${\n}    ${EMPTY}
    ${if_rc} =    BuiltIn.Set_Variable_If    """${rc}"""    *** Return code: ${rc}${\n}    ${EMPTY}
    OperatingSystem.Append_To_File    ${RESULTS_FOLDER}/output_${connection.alias}.log    ${time}${\n}*** Command: ${command}${\n}${if_stderr}${if_rc}${if_output}
