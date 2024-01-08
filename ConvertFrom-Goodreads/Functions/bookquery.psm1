using namespace System;
using namespace System.Collections.Generic;
using module ../Types/ConvertFromGoodReads.Types.psm1

##################[Instantiation Helper]#######################

function New-BookQuery {
  param(
    [BookMetadata]
    $metadata
  )
  try{
    return [BookQuery]::new($metadata)
  }
  catch {
    Write-ErrorLog `
      -MessageTemplate "Failed to Create BookQuery instance for {Title}" `
      -PropertyValues $metadata.bktitle `
      -ErrorRecord $_
    return $null
  }
}

##################[Determine Query Type]#######################
# No longer need this particular function after choosing to create search strings for all query types.
function Get-QueryType {
  param(
    [BookMetadata]
    $metadata
  )
  switch ($metadata){
    {$_.bkIdens.isbn13.Length -eq 13} {return 'isbn13'}
    {$_.bkIdens.isbn.Length -eq 10} {return 'isbn'}
    default {return 'noisbn'}
  }
}

##################[Create URIs]#######################
function New-SearchQueries {
  param(
    [ValidateSet('gbook','openlib')]
    [string]
    $uri_type,
    [BookMetadata]
    $metadata
  )
  $uri_str = switch($uri_type){
    'gbook'{$gbook_search}
    'openlib'{[string]::join('',@($openlib_urls.base_url,$openlib_urls.search_api))}
  }

  $search_q = [Stack[string]]::new()

  # First, push a query with the author's name and title
  $author_title=[string]::join(' ',@($metadata.bkAuthors[0],$metadata.bkQueryTitle));
  $search_q.push(
    $("{0}'{1}'" -f @($uri_str,$author_title.TrimStart().TrimEnd()))
  )
  switch($metadata.bkIdens){
    # Then push ISBN search string
    {$metadata.bkIdens.isbn.length -eq 10}{
      $search_q.push($([string]::join('',@($uri_str,$metadata.bkIdens.isbn))))
    }
    <#
      Finally, push the ISBN13 search string
      (we want this to be at the top of the stack)
    #>
    {$metadata.bkIdens.isbn13.length -eq 13}{
      $search_q.push($([string]::join('',@($uri_str,$metadata.bkIdens.isbn13))))
    }
  }
  return $search_q
}
