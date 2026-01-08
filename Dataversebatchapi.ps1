# URL for your Dataverse environment batch url
$batchRequestUrl = 'https://<dataverse environment url>/api/data/v9.2/$batch'

# Define Dataverse table url
$global:tableEndpointUrl = 'https://<dataverse environment url>/api/data/v9.2/<table name> '

# Read data from JSON file
$jsonData = Get-Content -Path "<filePath>.json" | ConvertFrom-Json 

# Get total number of records
$count = $jsonData.Count

# Define batch size
$batchSize = 900

# Loop through data in batches
while ($count -gt 0) {

    # Select records for the current batch
    $records = $jsonData | Select-Object -Skip $skip -First $batchSize

    # Generate batch unique GUID
    $batchId = "batch_" + [guid]::NewGuid().ToString()

    # Generate batch content type
    $batchContentType = "multipart/mixed;boundary=$batchId"

    # Define headers with your access token and other required headers
    $headers = @{
        'Authorization'     = "Bearer $global:token"
        'Content-Type'      = $batchContentType
        'Accept'            = 'application/json'
        'OData-Version'     = '4.0'
        'OData-MaxVersion'  = '4.0'
        'Prefer'            = 'odata.continue-on-error'
    }

    # Start building the body for the batch operation
    $body = ""

    foreach ($record in $records) {
        try {
            # Create the request body for each record
            $bodyObj = @{
                "title" = $record.title
            }

            # Add request to the batch body
            $body += "--$batchId`r`n"
            $body += "Content-Type: application/http`r`n"
            $body += "Content-Transfer-Encoding: binary`r`n`r`n"
            $body += "POST $global:tableEndpointUrl HTTP/1.1`r`n"
            $body += "Content-Type: application/json; type=entry`r`n`r`n"
            $body += "`r`n$($bodyObj | ConvertTo-Json)`r`n`r`n"
        }
        catch {
            # Handle errors if necessary
        }
    }

    # Add a GET request to the batch body (for example, to retrieve response)
    $body += "--$batchId`r`n"
    $body += "Content-Type: application/http`r`n"
    $body += "Content-Transfer-Encoding: binary`r`n`r`n"
    $body += "GET $global:tableEndpointUrl?%24top=1 HTTP/1.1`r`n`r`n"
    $body += "--$batchId--"

    # Make the batch request
    $response = Invoke-RestMethod -Uri $batchRequestUrl -Method Post -Headers $headers -Body $body

    # Update count and skip for the next batch
    $count -= $batchSize
    $skip += $batchSize
} 
