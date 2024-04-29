*** Settings ***
Library                         QForce
Library                         String
Library                         DateTime

*** Variables ***
# IMPORTANT: Please read the readme.txt to understand needed variables and how to handle them!!
${BROWSER}                      chrome
${username}                     pace.delivery1@qentinel.com.demonew
# ${login_url}                  https://qentinel--demonew.my.salesforce.com/            # Salesforce instance. NOTE: Should be overwritten in CRT variables
${home_url}                     ${login_url}/lightning/page/home

#Format dates
${date_format}                  %Y-%m-%d %H:%M:%S.%f
${display_format}               %d/%m/%Y

*** Keywords ***

Define login from CICD
    ${DYNAMIC_LOGIN}=           Get Variable Value          ${loginUrl}                 NoValuePassed
    IF                          '${DYNAMIC_LOGIN}' != 'NoValuePassed'
        GoTo                    ${DYNAMIC_LOGIN}
    ELSE
        GoTo                    ${LOCAL_LOGIN_URL}
        TypeText                Username                    ${ORG_USERNAME}
        TypeSecret              Password                    ${ORG_PASSWORD}
        ClickText               Log In
    END

Setup Browser
    # Setting search order is not really needed here, but given as an example
    # if you need to use multiple libraries containing keywords with duplicate names
    Set Library Search Order    QForce                      QWeb
    Open Browser                about:blank                 ${BROWSER}
    SetConfig                   LineBreak                   ${EMPTY}                    #\ue000
    Evaluate                    random.seed()               random                      # initialize random generator
    SetConfig                   DefaultTimeout              45s                         #sometimes salesforce is slow
    # adds a delay of 0.3 between keywords. This is helpful in cloud with limited resources.
    SetConfig                   Delay                       0.3

End suite
    Close All Browsers


Login
    [Documentation]             Login to Salesforce instance
    GoTo                        ${login_url}
    TypeText                    Username                    ${username}                 delay=1
    TypeText                    Password                    ${password}
    ClickText                   Log In
    # We'll check if variable ${secret} is given. If yes, fill the MFA dialog.
    # If not, MFA is not expected.
    # ${secret} is ${None} unless specifically given.
    ${MFA_needed}=              Run Keyword And Return Status                           Should Not Be Equal         ${None}                     ${secret}
    Run Keyword If              ${MFA_needed}               Fill MFA


Login As
    [Documentation]             Login As different persona. User needs to be logged into Salesforce with Admin rights
    ...                         before calling this keyword to change persona.
    ...                         Example:
    ...                         LoginAs                     Chatter Expert
    [Arguments]                 ${persona}
    ClickText                   Setup
    ClickText                   Setup for current app
    SwitchWindow                NEW
    TypeText                    Search Setup                ${persona}                  delay=2
    ClickElement                //*[@title\="${persona}"]                               delay=2                     # wait for list to populate, then click
    VerifyText                  Freeze                      timeout=45                  # this is slow, needs longer timeout
    ClickText                   Login                       anchor=Freeze               delay=1

Fill MFA
    ${mfa_code}=                GetOTP                      ${username}                 ${secret}                   ${login_url}
    TypeSecret                  Verification Code           ${mfa_code}
    ClickText                   Verify


Home
    [Documentation]             Navigate to homepage, login if needed
    GoTo                        ${home_url}
    ${login_status} =           IsText                      To access this page, you have to log in to Salesforce.                              2
    Run Keyword If              ${login_status}             Login
    ClickText                   Home
    VerifyTitle                 Home | Salesforce


    # Example of custom keyword with robot fw syntax
VerifyStage
    [Documentation]             Verifies that stage given in ${text} is at ${selected} state; either selected (true) or not selected (false)
    [Arguments]                 ${text}                     ${selected}=true
    VerifyElement               //a[@title\="${text}" and (@aria-checked\="${selected}" or @aria-selected\="${selected}")]


NoData
    VerifyNoText                ${data}                     timeout=3                   delay=2


DeleteAccounts
    [Documentation]             RunBlock to remove all data until it doesn't exist anymore
    ClickText                   ${data}
    ClickText                   Delete
    VerifyText                  Are you sure you want to delete this account?
    ClickText                   Delete                      2
    VerifyText                  Undo
    VerifyNoText                Undo
    ClickText                   Accounts                    partial_match=False


DeleteLeads
    [Documentation]             RunBlock to remove all data until it doesn't exist anymore
    ClickText                   ${data}
    ClickText                   Delete
    VerifyText                  Are you sure you want to delete this lead?
    ClickText                   Delete                      2
    VerifyText                  Undo
    VerifyNoText                Undo
    ClickText                   Leads                       partial_match=False

Today And Add Days
    [Documentation]
    [Arguments]                 ${add_days}
    ${today} =                  Get Current Date            result_format=${date_format}
    ${date_45_days_later} =     Add Time To Date            ${today}                    ${add_days} days            result_format=${date_format}
    ${formatted_45_days_later} =                            Convert Date                ${date_45_days_later}       result_format=${display_format}
    [Return]                    ${formatted_45_days_later}

Today
    [Documentation]
    [Arguments]
    ${today} =                  Get Current Date            result_format=${date_format}
    ${formatted_today} =        Convert Date                ${today}                    result_format=${display_format}
    [Return]                    ${formatted_today}
