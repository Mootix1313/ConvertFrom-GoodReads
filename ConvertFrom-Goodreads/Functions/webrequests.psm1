using module ../Types/ConvertFromGoodReads.Types.psm1
<##################[Invoke-Requests]#######################
Description/General Search Strategy:
  - perform query using provided string, qry.
  - convert response from json to psobject
  - select the 'items'/'docs' property where author and title from the resp match the metadata's
  - sort all remaining items by the publication year's distance from the metadata's
###########################################################>

<#Openlibrary specific search#>
function Invoke-OpenlibSearch {
  [OutputType([PSCustomObject])]
  param(
    [string]
    $qry,
    [pscustomobject]
    $metadata
  )
  try{
    $resp = Invoke-WebRequest $qry;
    $formatted_resp = Format-OpenlibResp -resp $resp -metadata $metadata
  }catch{
    Write-ErrorLog `
      -MessageTemplate $error_msgs.search `
      -PropertyValues $qry `
      -ErrorRecord $_
  }
  try{
    $qry = $([string]::join('', `
      @(
        $openlib_urls.base_url, `
        $formatted_resp.docs.key, `
        '.json'
      )
    ))
    $works_desc = Invoke-WebRequest $qry`
      | ConvertFrom-Json `
      | Select-Object `
        -ExpandProperty description `
        -ErrorAction SilentlyContinue
  }catch{
    return $formatted_resp
  }
  $formatted_resp | Add-Member -NotePropertyMembers @{'description'=$works_desc}
  return $formatted_resp
}
##################[End Region]#######################

<#Google Books specific search#>
function Invoke-GbookSearch {
  [OutputType([PSCustomObject])]
  param(
    [string]
    $qry,
    [pscustomobject]
    $metadata
  )
  try{
    $resp = Invoke-WebRequest $qry;
    $formatted_resp = Format-GbookResp `
      -resp $resp `
      -metadata $metadata
  }catch{
    Write-ErrorLog `
      -MessageTemplate $error_msgs.search `
      -PropertyValues $qry `
      -ErrorRecord $_
    return $null
  }
  return $formatted_resp
}
##################[End Region]#######################

<#
  A wrapper function to perform both Openlibrary &
  Google Book searches for a booklog item. Stores
  results within the query_items.results object.
#>
function Get-BookQueryResults {
  [OutputType([void])]
  param(
    [pscustomobject]
    $bklog
  )
  <#Collect Openlibrary Exemplars#>
  Write-InfoLog "------ [Openlibrary Queries] ------"
  
  foreach($qry in $bklog.query_items.olqueries){
    Write-InfoLog `
      -MessageTemplate "[OLQuery] {qry}" `
      -PropertyValues $qry

    $openlib_doc = Invoke-OpenlibSearch `
      -qry $qry `
      -metadata $bklog.metadata

    if( $openlib_doc -notlike $null){
      <#
        If a relevant response was captured,
        add it to the list
      #>
      $bklog.query_items.results.ol=$openlib_doc;
      break;
    }
  }
  <#Collect Google Book Exemplars#>
  Write-InfoLog "------ [Google Books Queries] ------"
  
  foreach($qry in $bklog.query_items.gbqueries){
    Write-InfoLog `
      -MessageTemplate "[GBQuery] {qry}" `
      -PropertyValues $qry

    $gbook_item = Invoke-GbookSearch `
      -qry $qry `
      -metadata $bklog.metadata

    if($gbook_item -notlike $null){
      <#
        If a relevant response was captured,
        add it to the list
      #>
      $bklog.query_items.results.gb=$gbook_item;
      break;
    }
  }
}
##################[End Region]#######################
