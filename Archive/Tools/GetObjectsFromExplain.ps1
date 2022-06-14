<# Get_Objects_From_Explain.ps1
    
    Author: Nick.salch@Microsoft.com (Nicksalc)
    This tool will take in an explain XML, then detect all fo the following
    that are mentioned in the explain plan:
        Databases
        Tables
        Columns
    It will also output update stats statements for all tables invovled in the query. 
    
    Output is placed under c:\temp\Timestamp_Folder
#>
param($ExplainXmlPath)

If(!$ExplainXmlPath)
{
    do
    {

        $ExplainXmlPath = Read-host "Please enter full path to XML"
        if (!(test-path $ExplainXmlPath)) 
        {
            Write-host -foregroundcolor red -backgroundcolor black "path not found"
        }ELSE{$goodPath=$true}
    
    }
    while(!$goodPath)
}


$date = get-date -Format MMddyyyy_hhmmss
$OutputFolder="C:\temp\$date\"
mkdir $OutputFolder -Force | out-null

$explainXml = Get-Content $ExplainXmlPath

#Remove the user query part of the query (this part can be messy so I jsut remove it)
$i=0
while (!($explainXml[$i] | select-string "total_number_operations="))
{
    $i++
}
$explainXml = $explainXml[$i..$explainXml.Length]

#Extract the db.schema.table names 

$objectList = $explainXml | Select-String "\[([^\[]*)\].\[([^\[]*)\].\[([^\[]*)\]" | select-string -NotMatch "qtabledb" |select-string -NotMatch "tempdb"  | % {$_.matches.value}
$objectList = $objectList | select -Unique
$objectList > "$OutputFolder\ObjectList.txt"
$tableList = $objectList | % {$_.split(".")[1] + "." +  $_.split(".")[2]}

#Extract Shuffle Columns
$shuffleColumnLines = ($explainXml | select-string "shuffle_columns")
$ShuffleColumns = @()
Foreach ($column in $shuffleColumnLines)
{
    $column = $column.ToString()
    $ShuffleColumns += $column.Substring($column.IndexOf(">")+1,$column.IndexOf(";")-$column.IndexOf(">")-1)
    
}
$ShuffleColumns = $ShuffleColumns | select -Unique |sort
$ShuffleColumns > "$OutputFolder\ShuffleColumns.txt"


#Extract the columns used
$involvedColumns=@()
Foreach ($string in (($explainXml | select-string " AND "," OR "," WHERE "," WHEN "," GROUP BY "," ELSE ") ))
{
    $SplitString = $string -split "]\.\["
    #$splitString.Count

    $counter = 1
    While ($counter -lt $splitString.count)
    {
        if($splitString[$counter].indexOf("]") -gt 0)
        {
            $involvedColumns += $splitString[$counter].Substring(0,$splitString[$counter].indexOf("]"))  
        }
        $counter++
    }

}

$involvedColumns += $ShuffleColumns
$involvedColumns = $involvedColumns | select -Unique | sort

#Write-host -foregroundcolor Cyan "`nInvolved Columns`n"
$involvedColumns > "$OutputFolder\involvedColumns.txt"

Write-Host -Foregroundcolor Cyan  "$($tableList.Count) Involved Tables Detected"
Write-host -Foregroundcolor Cyan  "$($ShuffleColumns.count) Shuffle Columns Detected"
Write-Host -Foregroundcolor Cyan  "$($involvedColumns.Count) Involved Columns Detected"

#create the update stats statements
$UpdateStatsStatements = @()

$UpdateStatsStatements += $tableList | % {"UPDATE STATISTICS $_"}
$UpdateStatsStatements > "$OutputFolder\tsql_UpdateStatsCommands.txt"

Write-host -ForegroundColor Cyan "`nOutput folder: $OutputFolder"
#>