[CmdletBinding()]
param (
    [Parameter()][string]$baseURL = "https://perftech.teamwork.com",
    [Parameter()][string]$userId = "326674",
    [Parameter(Mandatory)][string]$basicAuthKey,
    [Parameter()][string]$csvFile = ".\06-2023.csv"

)

Trap {
    $err = $_
    Write-Error $err
    #Stop-Transcript
    return $err
    exit 1
}
$ErrorActionPreference = 'Continue'


Add-Type -AssemblyName System.Web

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "Basic $basicAuthKey")

$entries = ConvertFrom-Csv -Delimiter ";" -InputObject $(Get-Content -Path $csvFile)
foreach ($entry in $entries) {

    $entryProject = [System.Web.HttpUtility]::UrlEncode($entry.Project)
    $res_GetProject = Invoke-RestMethod "$baseURL/projects.json?searchTerm=$entryProject" -Method 'GET' -Headers $headers
    Write-Debug $res_GetProject | ConvertTo-Json

    if ($res_GetProject.status -ne "OK") { throw "Could not retrieve project: [$($entry.Project)].  STATUS: $($res_GetProject.STATUS)." }
    if ($res_GetProject.projects.Count -eq 1) {
        $project = $res_GetProject.projects[0]
    }
    else {
        throw "More than one project was retrieved with the searchTerm=[$entries[0]]"
    }

    # Get TaskList From Project
    $entryTaskList = [System.Web.HttpUtility]::UrlEncode($entry.TaskList)
    $res_GetTaskList_FromProject = Invoke-RestMethod "$baseURL/projects/$($project.id)/tasklists.json?searchTerm=$entryTaskList" -Method 'GET' -Headers $headers
    Write-Debug $res_GetTaskList_FromProject | ConvertTo-Json

    if ($res_GetTaskList_FromProject.status -ne "OK") { 
        throw "Could not retrieve task list. TaskList:[$($entry.TaskList)]. [$($res_GetTaskList_FromProject | Out-String)]." 
    }
    
    # Get Task from TaskList
    $entryTask = $entry.Task
    $res_GetTask_FromTaskList = Invoke-RestMethod "$baseURL/tasklists/$($res_GetTaskList_FromProject.tasklists.id)/tasks.json" -Method 'GET' -Headers $headers
    Write-Debug $res_GetTask_FromTaskList | ConvertTo-Json

    $task = $($res_GetTask_FromTaskList."todo-items" | Where-Object { $_.content -eq $entryTask })
    Write-Debug $task | Out-String
    $taskId = $task.id

    # Prepare object for body
    
    $timeLog = New-Object PSCustomObject
    Add-Member -InputObject $timeLog -MemberType NoteProperty -Name "person-id" -Value $userId
    Add-Member -InputObject $timeLog -MemberType NoteProperty -Name "date" -Value $([Datetime]::ParseExact("$($entry.Date)", 'dd/MM/yyyy', $null)).ToString('yyyyMMdd')
    Add-Member -InputObject $timeLog -MemberType NoteProperty -Name "time" -Value $entry.StartTime
    Add-Member -InputObject $timeLog -MemberType NoteProperty -Name "hours" -Value $([int]$(($entry.Duration).Split(":")[0]))
    Add-Member -InputObject $timeLog -MemberType NoteProperty -Name "minutes" -Value $([int]$(($entry.Duration).Split(":")[1]))
    Add-Member -InputObject $timeLog -MemberType NoteProperty -Name "isbillable" -Value $entry.Billable

    if ($entry.Description) { Add-Member -InputObject $timeLog -MemberType NoteProperty -Name "description" -Value $entry.Description }
    if ($entry.Tags) { Add-Member -InputObject $timeLog -MemberType NoteProperty -Name "tags" -Value $entry.Tags }

    $timeEntry = New-Object PSCustomObject
    Add-Member -InputObject $timeEntry -MemberType NoteProperty -Name "time-entry" -Value $timeLog

    $body = $timeEntry | ConvertTo-Json    
    Write-Debug $body

    # Log entry
    if ($taskId) {
        #### Create TimeLog in Task
        $res_TimeEntry = Invoke-RestMethod "$baseURL/tasks/$taskId/time_entries.json" -Method 'POST' -Headers $headers -Body $body
    }
    else {
        #### Create TimeLog in Project
        $res_TimeEntry = Invoke-RestMethod "$baseURL/projects/$($project.id)/time_entries.json" -Method 'POST' -Headers $headers -Body $body
    }
    Write-Debug $res_TimeEntry | ConvertTo-Json
    
    if ($res_TimeEntry.STATUS -ne "OK") {
        throw "$($entry | Out-String) could not be added. [$($res_TimeEntry | Out-String)]"
    }
    else {
        Write-Host "Added time entry with id: [$($res_TimeEntry.timeLogId)]"
    }
}