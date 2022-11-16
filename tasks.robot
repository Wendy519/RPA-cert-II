*** Settings ***
Documentation       Get orders from CSV files
...                 Enter them into the web form
...                 save the results, with picture of robot to PDF
...                 Archive the resulting pdf files

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Tables
Library             RPA.RobotLogListener
Library             RPA.Robocorp.Vault
Library             RPA.Dialogs
Library             String
Library             OperatingSystem


*** Tasks ***
Enter orders and store copies in PDF format
    Download csv of order info
    Save user input for message    $usermsg
    Open ordering website
    Enter sales data in form
    Save created files in an Archive and cleanup


*** Keywords ***
Download csv of order info
    ${download-url}=    Get Secret    downloadfile
    Download    ${download-url}[url]

Get custom message from user
    Add heading    Add a custom message to receipts
    Add text input    message
    ...    label=message
    ...    rows=5
    ...    placeholder=Enter your message here
    ${receipt}=    Run dialog
    RETURN    ${receipt.message}

Save user input for message
    [Arguments]    ${usermsg}
    ${usermsg}=    Get custom message from user
    Create File    ${OUTPUT_DIR}${/}custom-message.txt    ${usermsg}

Open ordering website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get past the modal
    Wait Until Element Is Visible    css:.modal
    Click Button    OK

Order button Click
    Click Button    Order
    ${IsElementVisible}=    Is Element Visible    css:div.alert-danger
    IF    ${IsElementVisible}    Order button Click

Individual order entry
    [Arguments]    ${robot_specs}
    ${ORDERNUM}=    Set Variable    ${robot_specs}[Order number]
    Select From List By Value    head    ${robot_specs}[Head]
    Select Radio Button    body    ${robot_specs}[Body]
    Input Text    css:.form-control    ${robot_specs}[Legs]
    Input Text    address    ${robot_specs}[Address]
    Click Button    Preview
    Wait Until Element Is Visible    css:div#robot-preview-image
    Screenshot    css:div#robot-preview-image    ${OUTPUT_DIR}${/}files${/}robot.png

    Order button Click

Save order to PDF
    Wait Until Element Is Visible    id:receipt
    ${receiptnum}=    Get Text    css:.badge-success
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${image}=    Set Variable    ${OUTPUT_DIR}${/}files${/}robot.png
    ${usermsg}=    Get File    ${OUTPUT_DIR}${/}custom-message.txt
    ${TEMPLATE}=    Set Variable    devdata/receipt.template
    ${PDF}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}${receiptnum}.pdf
    ${DATA}=    Create Dictionary
    ...    receipt=${receipt}
    ...    image=${image}
    ...    usermsg=${usermsg}
    Template HTML To PDF
    ...    template=${TEMPLATE}
    ...    output_path=${PDF}
    ...    variables=${DATA}

Order Another
    Click Button    id:order-another

Enter sales data in form
    ${orderdata}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orderdata}
        Get past the modal
        Individual order entry    ${order}
        Save order to PDF
        Order Another
    END

Save created files in an Archive and cleanup
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}Receipts.zip
    RPA.FileSystem.Remove Directory    ${OUTPUT_DIR}${/}receipts    recursive=${True}
    RPA.FileSystem.Remove File    orders.csv
    RPA.FileSystem.Remove File    ${OUTPUT_DIR}${/}custom-message.txt
