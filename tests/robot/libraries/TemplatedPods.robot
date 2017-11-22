*** Settings ***
Documentation     This is an extension to PodManagement with keywords getting data from template files.
Resource          ${CURDIR}/all_libs.robot

*** Keywords ***
Subtitute_Yaml_Template
    [Arguments]    ${template}    ${name}    ${replicas}=1    ${location}=client_node
    [Documentation]    Log and return result of substituting fields in template.
    BuiltIn.Log_Many    ${template}    ${name}    ${replicas}    ${location}
    &{mapping} =    Builtin.Create_Dictionary    NAME=${name}    REPLICAS=${replicas}    LOCATION=${location}
    ${result} =    BuiltIn.Evaluate    string.Template('''${template}''').safe_substitute(${mapping})    modules=string
    BuiltIn.Log    ${result}
    [Return]    ${result}

Deploy_Templated_Pods_And_Verify_Running
    [Arguments]    ${template_file}    ${name}    ${replicas}=1    ${location}=client_node    ${namespace}=defaut    ${options}=${EMPTY}    ${timeout}=30s    ${check_period}=5s
    [Documentation]    Read yaml template from file, substitute field values, proceed with Deploy_Text_Pods_And_Verify_Running.
    BuiltIn.Log_Many    ${template_file}    ${name}    ${replicas}    ${location}    ${namespace}    ${options}    ${timeout}    ${check_period}
    BuiltIn.Comment    TODO: Could namespace could also be considered a field to configure in a template?
    ${template} =    OperatingSystem.Get_File    ${template_file}
    ${text} =    Subtitute_Yaml_Template    ${template}    ${name}    ${replicas}    ${location}
    ${pod_names} =    PodManagement.Deploy_Text_Pods_And_Verify_Running    ${text}    ${name}    ${replicas}    ${location}    ${namespace}    ${options}    ${timeout}    ${check_period}

Remove_Templated_Pods_And_Verify_Removed
    [Arguments]    ${template_file}    ${name}    ${replicas}=1    ${location}=client_node    ${namespace}=default    ${options}=${EMPTY}    ${expected_rc}=0    ${ignore_stderr}=${False}    ${timeout}=30s    ${check_period}=5s
    [Documentation]    Read yaml template from file, substitute field values, proceed with Remove_Text_Pods_And_Verify_Removed.
    BuiltIn.Log_Many    ${template_file}    ${name}    ${replicas}    ${location}    ${namespace}    ${options}    ${expected_rc}    ${ignore_stderr}    ${timeout}    ${check_period}
    ${template} =    OperatingSystem.Get_File    ${template_file}
    ${text} =    Subtitute_Yaml_Template    ${template}    ${name}    ${replicas}    ${location}
    BuiltIn.Run_Keyword_And_Return    PodManagement.Remove_Text_Pods_And_Verify_Removed    ${text}    ${name}    ${namespace}    ${options}    ${expected_rc}    ${ignore_stderr}    ${timeout}    ${check_period}

With_Item_Data
    [Arguments]    ${item}    ${keyword}    @{args}    &{kwargs}
    [Documentation]    Extract item data, call keyword with data arguments supplied.
    BuiltIn.Log_Many    ${item}    ${keyword}    ${args}    ${kwargs}
    ${file_name} =    Collections.Get_From_Dictionary    ${item}    template
    ${file_path} =    BuiltIn.Set_Variable    ${CURDIR}/../resources/templates/${file_name}
    ${name} =    Collections.Get_From_Dictionary    ${item}    name
    ${replicas} =    Collections.Get_From_Dictionary    ${item}    replicas
    ${location} =    Collections.Get_From_Dictionary    ${item}    location
    BuiltIn.Run_Keyword_And_Return    ${keyword}    ${file_path}    ${name}    ${replicas}    ${location}    @{args}    &{kwargs}

For_Every_Item
    [Arguments]    ${pod_set_object}    ${keyword}    @{args}    &{kwargs}
    [Documentation]    Extract item list, for each item proceed call With_Item_Data.
    BuiltIn.Log_Many    ${pod_set_object}    ${keyword}    ${args}    ${kwargs}
    ${item_list} =    Collections.Get_From_Dictionary    ${pod_set_object}    pod_set
    : FOR    ${item}    IN    @{item_list}
    \    ${return} =    With_Item_Data    ${item}    ${keyword}    @{args}    &{kwargs}

Deploy_Pod_Set_Object
    [Arguments]    ${pod_set_object}    @{args}    &{kwargs}
    [Documentation]    Given pod set object, deploy all defined pods.
    BuiltIn.Log_Many    ${pod_set_object}    ${args}    ${kwargs}
    For_Every_Item    ${pod_set_object}    Deploy_Templated_Pods_And_Verify_Running    @{args}    &{kwargs}

Remove_Pod_Set_Object
    [Arguments]    ${pod_set_object}    @{args}    &{kwargs}
    [Documentation]    Given pod set object, delete all defined pods.
    BuiltIn.Log_Many    ${pod_set_object}    ${args}    ${kwargs}
    For_Every_Item    ${pod_set_object}    Remove_Templated_Pods_And_Verify_Removed    @{args}    &{kwargs}
