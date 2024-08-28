$location = "uksouth"

$env = (get-azcontext).Subscription.Name -replace "sis-", ""

$storageAccts = Get-AzResource -ResourceType 'Microsoft.Storage/storageAccounts' | Where-Object { $_.location -eq $location}

Write-Output "--- Echo storage accounts:"
write-output $storageAccts | Format-Table
Write-output "--- Finished echoing storage accounts."

$tableStorageList = @()
$noTablesList = @()

$storageAccts | ForEach-Object {
    $storageAcct = Get-AzStorageAccount -ResourceGroupName $_.ResourceGroupName -Name $_.Name
    $tables = Get-AzStorageTable -Context $storageAcct.Context
    try {
        $tables = Get-AzStorageTable -Context $storageAcct.Context
        if (-not $null -eq $tables) {
            $tableStorage = [PSCustomObject]@{
                ResourceGroupName = $storageAcct.ResourceGroupName
                StorageAccountName = $storageAcct.StorageAccountName
                TableNames = $tables.Name
            }
            $tableStorageList += $tableStorage
        } else {
            $noTablesList += $storageAcct.StorageAccountName
        }
    }
    catch {
        $noTablesList += $storageAcct.StorageAccountName
    }
}

Write-Output $tableStorageList | Sort-Object StorageAccountName | Format-Table
Write-Output ""
Write-Output $noTablesList | Sort-Object
Write-Output ""
Write-Output "Number of accounts without tables: $($noTablesList.count)"
Write-Output "Number of accounts with tables: $($tableStorageList.count)"
Write-Output "Total number of accounts: $($storageAccts.count)"

$tableStorageList | Sort-Object StorageAccountName | ConvertTo-Json -Depth 100 | Set-Content -path (Join-Path "data" "tableStorageList.$env.json")
$noTablesList | Sort-Object | Set-Content -path (Join-Path "data" "noTablesList.$env.txt")