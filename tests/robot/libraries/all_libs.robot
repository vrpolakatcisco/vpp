*** Settings ***
Documentation     Aggregate library for all Suites and Resources to include.
...
...               It is easier to maintain suites and resources if import section is just one line.
...               As the amount of libraries is small, there should be no downsides,
...               long as Library.Keyword call format is used.
Library           Collections
Library           OperatingSystem
Library           SSHLibrary
Library           String
Library           ${CURDIR}/kube-parser.py
Library           ${CURDIR}/pod_set.py
Resource          ${CURDIR}/KubeExec.robot
Resource          ${CURDIR}/KubeManagement.robot
Resource          ${CURDIR}/NamedPods.robot
Resource          ${CURDIR}/NamedVms.robot
Resource          ${CURDIR}/NodeManagement.robot
Resource          ${CURDIR}/PodManagement.robot
Resource          ${CURDIR}/ShellOverSsh.robot
Resource          ${CURDIR}/SshCommons.robot
Resource          ${CURDIR}/StatefulSetup.robot
Resource          ${CURDIR}/TemplatedPods.robot
Resource          ${CURDIR}/setup-teardown.robot
