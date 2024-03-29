<#
Details: Graph / PowerShell Script t populate user contacts based on CSV input, 
        Please fully read and test any scripts before running in your production environment!
        .SYNOPSIS
        Populates mail contacts into user mailboxes from a CSV

        .DESCRIPTION
        Creates a new mail contact for each entry in the input CSV in the target mailbox.

        .PARAMETER Mailbox
        User Principal Name of target mailbox

        .PARAMETER CSVPath
        Full path to the input CSV

        .PARAMETER ClientID
        Application (Client) ID of the App Registration

        .PARAMETER ClientSecret
        Client Secret from the App Registration

        .PARAMETER TenantID
        Directory (Tenant) ID of the Azure AD Tenant

        .EXAMPLE
        .\graph-PopulateContactsFromCSV.ps1 -Mailbox  $mailbox -ClientSecret $clientSecret -ClientID $clientID -TenantID $tenantID -CSVPath $csv
        
#>
#>
#################################################
####################FONCTIONS####################
#################################################
function GetGraphToken {
    # Azure AD OAuth Application Token for Graph API
    # Get OAuth token for a AAD Application (returned as $token)
<#
        .SYNOPSIS
        This function gets and returns a Graph Token using the provided details
    
        .PARAMETER clientSecret
        -is the app registration client secret
    
        .PARAMETER clientID
        -is the app clientID
    
        .PARAMETER tenantID
        -is the directory ID of the tenancy
#>
    Param(
        [parameter(Mandatory = $true)]
        [String]
        $ClientSecret,
        [parameter(Mandatory = $true)]
        [String]
        $ClientID,
        [parameter(Mandatory = $true)]
        [String]
        $TenantID
    
    )
    
    # Construct URI
    $uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
         
    # Construct Body
    $body = @{
        client_id     = $clientId
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $clientSecret
        grant_type    = "client_credentials"
    }
         
    # Get OAuth 2.0 Token
    $tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
         
    # Access Token
    $token = ($tokenRequest.Content | ConvertFrom-Json).access_token
    return $token
}

function ImportContact {
    <#
.SYNOPSIS
Imports contact into specified user mailbox

.DESCRIPTION
This function accepts an AAD token, user account and contact object and imports the contact into the users mailbox

.PARAMETER Mailbox
User Principal Name of target mailbox

.PARAMETER Contact
Contact object for processing

.PARAMETER Token
Access Token      
#>
    Param(
        [parameter(Mandatory = $true)]
        [String]
        $Token,
        [parameter(Mandatory = $true)]
        [String]
        $Mailbox,
         [parameter(Mandatory = $true)]
        [String]
        $folder,
        [parameter(Mandatory = $true)]
        [PSCustomObject]
        $contact
    
    )
    write-host "contactcompanyname $($contact.companyname)"
    write-host $contact
    #Creation de l'objet "contact"
    $ContactObject = @"
    {
        "assistantName": "$($contact.assistantName)",
        "businessHomePage": "$($contact.businessHomePage)",
        "businessPhones": [
            "$($contact.businessPhones)"
          ],
        "displayName": "$($contact.displayName)",
        "emailAddresses": [
            {
                "address": "$($contact.emailaddress)",
                "name": "$($contact.displayname)"
            }
        ],
        "givenName": "$($contact.givenname)",
        "middleName": "$($contact.middleName)",
        "nickName": "$($contact.nickName)",
        "surname": "$($contact.surname)",
        "title": "$($contact.title)"
    }
"@
    write-host "contact object: $contactobject"

#Creation du token d'autentification pour chaque boite mail contenue dans cible.txt
foreach($mail in $CSVPath){
    $apiUri = "https://graph.microsoft.com/v1.0/users/$person/contactFolders/$folderid/contacts"
    write-host $apiuri
  
        $NewContact = (Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)" } -ContentType 'application/json' -Body $contactobject -Uri $apiUri -Method Post)
        return $NewContact
         }
    catch {
        throw "Error creating contact $($contact.emailaddress) for $person $($_.Exception.Message)"
        continue
        }
}
                    
                    

##Import CSV
try {
    $Contacts = import-csv $CSVPath -ErrorAction stop
}
catch {
    throw "Erreur d'import CSV: $($_.Exception.Message)"
    break
}

##Graph Token
Try {
    $Token = GetGraphToken -ClientSecret $ClientSecret -ClientID $ClientID -TenantID $TenantID
}
catch {
    throw "Erreur d'obtention de token"
    break
}

##ProcessImport
foreach ($contact in $contacts) {
    $NewContact = ImportContact -Mailbox $person -token $token -contact $contact -folder "Sync-Opac"
}
