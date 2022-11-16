*** Settings ***
Documentation       Enter orders and store copies in PDF format archived in zip

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             Dialogs
Library             RPA.Tables
Library             RPA.RobotLogListener


*** Tasks ***
Enter orders and store copies in PDF format
    Download csv of order info
    Open ordering website
    Enter sales data in form
    Save created files in an Archive and cleanup


*** Keywords ***
Download csv of order info
    Download    https://robotsparebinindustries.com/orders.csv

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
    ${TEMPLATE}=    Set Variable    devdata/receipt.template
    ${PDF}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}${receiptnum}.pdf
    ${DATA}=    Create Dictionary
    ...    receipt=${receipt}
    ...    image=${image}
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
    Remove Directory    ${OUTPUT_DIR}${/}receipts    recursive=${True}
    Remove File    orders.csv
