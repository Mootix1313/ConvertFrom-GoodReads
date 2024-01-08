using namespace System.Collections.Generic;
using namespace System.Text;
using module ../Types/ConvertFromGoodReads.Types.psm1

function Import-GoodreadsLibrary {
  [OutputType([List[BookLog]])]
  [CmdletBinding(DefaultParameterSetName='default')]
  param(
    [Parameter(ParameterSetName='default')]
    [Parameter(ParameterSetName='indicies')]
    [string]
    $goodreads_filepath,
    [Parameter(ParameterSetName='indicies')]
    [Int32]
    $starting_index=0,
    [Parameter(ParameterSetName='indicies')]
    [Int32]
    $stopping_index=-1,
    [Parameter(ParameterSetName='grouped_obj')]
    [pscustomobject]
    $goodreads_subset
  )
  begin{
    $booklogs = [List[BookLog]]::new();
    switch($PSCmdlet.ParameterSetName){
      'grouped_obj'{$toProcess = $goodreads_subset;break;}
      'indicies'{
        #course correct the provided indicies, if need be.
        switch($starting_index){
          {$_ -ge $export.count}{$starting_index = $export.count - 1;}
          {$_ -lt 0}{$starting_index = 0;}
        }
        switch($stopping_index){
          {$_ -ge $export.count}{$stopping_index = $export.count - 1;break;}
          {$_ -lt $starting_index}{$stopping_index = $starting_index;}
        }
        $toProcess = $(
          $(Get-Content $goodreads_filepath `
            | convertfrom-csv)[$starting_index..$stoping_index] `
              | Group-Object -Property Title `
              | Sort-Object -Property Title
        )
      }
      'default'{
        $toProcess = $(
          $(Get-Content $goodreads_filepath | convertfrom-csv) `
            | Group-Object -Property Title `
            | Sort-Object -Property Title
        )
      }
    }
    $dupes = $toProcess.where({$_.Count -gt 1})

    Write-InfoLog `
      -MessageTemplate $info_msgs.start `
      -PropertyValues @(
        $export.Count,
        $dupes.Count,
        $toProcess.Count
      )
    if($dupes.count -ge 1){
      Write-InfoLog `
      -MessageTemplate $info_msgs.dupes `
      -PropertyValues @(
        [System.Environment]::NewLine,
        $([string]::join(
          [System.Environment]::NewLine,
          $dupes.Name.ForEach({"'$($_)'"})
        ))
      )
    }
  }
  process{
    foreach($entry in $toProcess){
      if($entry.Count -gt 1){
        $curr_grp = $(
          $entry.Group `
          | Sort-Object -Property 'Year Published' -Descending `
          | Select-Object -First 1
        )
      }else{
        $curr_grp = $entry.Group[0]
      }
      $curr_booklog = New-BookLog $curr_grp
      if($curr_booklog -notlike $null){
        $booklogs += $curr_booklog;
        Write-InfoLog `
          -MessageTemplate $info_msg.import `
          -PropertyValues @(
            $(($booklogs.Count/$toProcess.Count)*100),
            $curr_grp.Title
          )
      }else{
        Write-ErrorLog `
          -MessageTemplate $error_msgs.failed_import `
          -PropertyValues @(
            $(($booklogs.Count/$toProcess.Count)*100),
            $curr_grp.Title
          ) `
          -ErrorRecord $_
      }
    }
  }
  end{
    return $booklogs
  }
}

function Build-BookLog {
  [OutputType([string])]
  Param(
    [BookLog]
    $bklog
  )
  <#
    - Convert data to YAML (frontmatter)
    - Return combination of frontmatter and booklog_content
  #>
  $raw_log = [StringBuilder]::new();
  # Try to avoid requerying and remerging data unnecessarily
  if(-not $bklog.built){
    # Retrieve openlibrary & gbook results
    Get-BookQueryResults $bklog

    # Combine recieved results & distill metadata
    Merge-BookData $bklog

    # switch 'built' status
    $bklog.built = $true;
  }

  # Build the frontmatter string
  $bklog_metadata=$(Format-FrontMatter $bklog);

  # Build the entire raw_log object
  $raw_log.AppendLine("---") >$null;
  $raw_log.Append($bklog_metadata) >$null;
  $raw_log.AppendLine("---") >$null;
  $raw_log.AppendLine("") >$null;
  $raw_log.Append($booklog_content) >$null;

  return $raw_log.ToString();
}

function Merge-BookData {
  [OutputType([void])]
  param(
    [pscustomobject]
    $bklog
  )

  # retrieve, merge, and filter query results
  $merged_data=$(
    $(Get-FlattenedObject -flattenMe $bklog.query_items.results.ol) + `
    $(Get-FlattenedObject -flattenMe $bklog.query_items.results.gb) `
      | Limit-PropertiesByFilter
  )
  # place merged data in correct metadata properties
  switch($merged_data){
    # Book Cover URLs
    {$_.Name -cmatch 'cover_i'}{$bklog.metadata.bkCover.ol=$(
      "{0}{1}" -f @($openlib_urls.cover_api,$_.Values));}
    {$_.Name -cmatch 'thumbnail'}{$bklog.metadata.bkCover.gb = $_.Values;}
    
    # Book Genres/Categories
    {$_.Name -cmatch 'subject'}{
      $bklog.metadata.bkCategories.add($_.Values)>$null;}
    {$_.Name -cmatch 'categories'}{
      $bklog.metadata.bkCategories.add($_.Values)>$null;}
    
    # ISBNs
    {$_.Name -cmatch 'isbn'}{
      if($bklog.metadata.bkIdens.isbn13.Length -eq 0){
        $bklog.metadata.bkIdens.isbn13 = $_.Values.where({$_.length -eq 13});
      }elseif($bklog.metadata.bkIdens.isbn.Length -eq 0){
        $bklog.metadata.bkIdens.isbn = $_.Values.where({$_.length -eq 10});
      }
    }
    {$_.Name -cmatch 'industryIdentifiers'}{
      $isbns = $_.Values;
      if($bklog.metadata.bkIdens.isbn13.Length -eq 0){
        $bklog.metadata.bkIdens.isbn13 = $isbns.where({$_.type -eq "ISBN_13"}).identifier
      }elseif($bklog.metadata.bkIdens.isbn.Length -eq 0){
        $bklog.metadata.bkIdens.isbn = $isbns.where({$_.type -eq "ISBN_10"}).identifier
      }
    }
    
    # Classifications (Library of Congress & Dewey Decimal)
    {$_.Name -cmatch 'lcc_sort'}{
      $bklog.metadata.bkIdens.lcc_sort = $_.Values;}
    {$_.Name -cmatch 'dcc_sort'}{
      $bklog.metadata.bkIdens.dcc_sort = $_.Values;}
    
    # Book reviews
    {$_.Name -cmatch 'ratings_average'}{
      $bklog.metadata.bkAvgRatings.openlib=$_.Values;}
    {$_.Name -cmatch 'averageRating'}{
      $bklog.metadata.bkAvgRatings.gbook=$_.Values;}

    # Description of the book, whichever comes first
    {$_.Name -cmatch 'description'}{
      if(-not ($bklog.metadata.bkDescr -like $null) ){
        $_.Values;
      }
    }
    {$_.Name -cmatch 'textSnippet'}{
      if(-not ($bklog.metadata.bkDescr -like $null) ){
        $_.Values;
      }
    }

    # References to openlibrary/google book results
    {$_.Name -cmatch 'selfLink'}{$bklog.metadata.bkURLs.gbook=$_.Values;}
    {$_.Name -cmatch 'key'}{
      $bklog.metadata.bkURLs.openlib=$(
        $_.Values.foreach({"{0}{1}" -f@($openlib_urls.base_url,$_)})
      )
    }
  }
}

function Format-FrontMatter {
  [OutputType([string])]
  param(
    [BookLog]
    $bklog
  )
  $frontmatter_str_bldr = [StringBuilder]::new();
  $printable_metadata = $bklog.metadata.psobject.properties `
    | Limit-PropertiesByName `
    | Select-object @{
      Expression={$frontmatter_mapping[$_.Name]};Label="Name"
    },Value `
    | Sort-Object -Property Name

  $printable_metadata `
    | ForEach-Object {
      <#
        YamlDotNet freaks out when trying to serialize
        an empty SortedSet (only 'book-categories' has this).
        To avoid the freakout, set an empty set to an empty
        string.
      #>
      if($_.Value -like $null){$_.Value = ''}
      $frontmatter_str_bldr.Append(
        $(ConvertTo-Yaml -Data @{$_.Name=$_.Value})
      ) >$null;
    }

  return $frontmatter_str_bldr.ToString()
}

function Get-FlattenedObject {
  [OutputType([pscustomobject])]
  param(
    [pscustomobject]
    $flattenMe
  )
  <# 
    Return object if doesn't have 
    (note)properties or a potential array of 
    objects with them.
  #>
  if($flattenMe -like $null){return $flattenMe}
  #
  $currtype = $flattenMe.gettype().Name
  #
  if(-not $($currtype -match 'pscustomobject' -or $currtype -match '\[\]')){return $flattenMe}

  $result = [List[string]]::new()
  $procMe = [stack[pscustomobject]]::new()

  # initialize processing stack
  $flattenMe.psobject.properties `
    | Limit-PropertiesByMemberType `
    | Group-Object -Property TypeNameOfValue `
    | ForEach-Object{ $procMe.push($_)}

  while($procMe.count -ne 0){
    $curr_grp = $procMe.pop()
    switch -Regex ($curr_grp.Name){
      'pscustomobject'{
        # Case: custom object
        $curr_grp.Group `
          | ForEach-Object { 
            $_.Value.psobject.properties `
            | Limit-PropertiesByMemberType `
            | Group-Object -Property TypeNameOfValue
          } `
          | ForEach-Object{$procMe.push($_)}
      }
      '\[\]'{
        # Case: array typed items
        # Check the first group items' array to determine the value of
        # its first item. Assume remaining are of the same type.
        switch -Regex ($curr_grp.Group[0].Value[0].gettype().Name){
          'pscustomobject'{
            $curr_grp.Group `
            | ForEach-Object {
              foreach($item in $_.Value) {
                $item.psobject.properties `
                | Limit-PropertiesByMemberType `
                | Group-Object -Property TypeNameOfValue
              }
            } | ForEach-Object{$procMe.push($_)}
          }
          '\[\]'{
            $curr_grp.Group `
              | ForEach-Object {
                $val = $($_.Value | ConvertTo-Json -depth 20 -Compress)
                $result.Add([string]::join('=',@($_.Name,$val)))
            }
          }
          default{
            $curr_grp.Group `
              | ForEach-Object {
                $val = $($_.Value | ConvertTo-Json -depth 20 -Compress)
                $result.Add([string]::join('=',@($_.Name,$val)))
            }
          }
        }
      }
      default{
      # Case: scalar valued items
        $curr_grp.Group `
          | ForEach-Object{
            $result.Add(
              $([string]::join('=',@($_.Name,$_.Value)))
            )
        }
      }
    }
  }

  $flattened = $result `
    | ForEach-Object {
      $curr=$_.split("=",2); 
      $name = $curr[0];
      $val = try{$curr[1]|ConvertFrom-Json}catch{$curr[1]}
      @{$name=$val}
    } `
    | Group-Object @{Expression={$_.Keys}} `
    | Select-Object Name,@{Expression={$_.Group.Values};Label='Values'}

  return $flattened
}

function Format-OpenlibResp {
  [OutputType([pscustomobject])]
  param (
    [pscustomobject]
    $resp,
    [BookMetadata]
    $metadata
  )
  $authors = $metadata.bkAuthors
  $title = $metadata.bkQueryTitle
  $year_published = $metadata.bkPubDates.'year-published'
  return $($resp `
    |ConvertFrom-Json `
    |Where-Object {
      # if ISBN search, do isbns match?
      ($_.q -in $_.docs.editions.docs.isbn) `
      -or `
      # Otherwise, make sure the author and title match the metadata
      (($authors -match $_.author_name) `
      -and `
      ($title -match $_.docs.title))
    } `
    |Sort-Object @{Expression={$regex_utils.pubyr.Match(`
      $_.docs.editions.docs.publish_date).Value - $year_published}} `
    |Select-Object -First 1)
}

function Format-GbookResp {
  [OutputType([pscustomobject])]
  param (
    [pscustomobject]
    $resp,
    [BookMetadata]
    $metadata
  )
  $authors = $metadata.bkAuthors
  $title = $metadata.bkQueryTitle
  $year_published = $metadata.bkPubDates.'year-published'

  return $(
    $resp `
      | ConvertFrom-Json `
      | Select-Object -ExpandProperty items `
      | Where-Object{
        ($authors -match $_.volumeInfo.authors) -and ($title -match $_.volumeInfo.title)
      } | Sort-Object @{Expression={$regex_utils.pubyr.Match($_.volumeInfo.publishedDate).Value - $year_published}} `
      | Select-Object -First 1
  )
}
