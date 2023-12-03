function Get-FlattenedObject {
  param(
    [PSCustomObject]
    $curr_fields
  )
  $process_stack = [System.Collections.Stack]::new($curr_fields)
  $result = [System.Collections.Stack]::new()

  while ($process_stack.Count -ne 0) {
    $curr_item = $process_stack.Pop()
    if (
      [pscustomobject].IsInstanceOfType($curr_item.Value)){
      $curr_item.Value.PSObject.Properties.where({$_.MemberType -eq 'NoteProperty'}) |
        Select-Object Name, Value |
      ForEach-Object {
        $process_stack.Push($_)
      }
    }
    else {
      $result.Push($curr_item)
    }
  }
  return $result
}

function Get-FormattedObject {
  param (
    [psobject]
    $curr_item
  )
  if($curr_item -ilike $null) {return $null}
  $keyed_obj = $curr_item.PSObject.Properties.where({$_.MemberType -eq 'NoteProperty'}) `
  | Select-Object Name, Value
  return $keyed_obj
}

function New-LogName {
  param(
    [PSCustomObject]
    [Parameter(Mandatory=$true)]
    $curr_item
  )
  $invalidChars = [regex]::new(
    [System.IO.Path]::GetInvalidFileNameChars(),
    @('Compiled', 'Singleline'),
    [timespan]::FromSeconds(3)
  )
  $opy = $curr_item.where({ $_.Name -eq 'original-publication-year' }).Value
  $yp = $curr_item.where({ $_.Name -eq 'year-published' }).Value
  $author = $curr_item.where({ $_.Name -eq 'author'}).Value
  $title = $curr_item.where({ $_.Name -eq 'title'}).Value

  $name_seeds = @(
    $($opy -ilike $null ? $yp : $opy).replace(" ","_"),
    $author.replace(" ", "_"),
    $title.replace(" ", "_")
  )
  
  return $invalidChars.Replace(
    $([string]::Join('-', $name_seeds)+".md"),'')
}

function New-BookTags {
  Param(
    [PSCustomObject]
    [Parameter(Mandatory = $true)]
    $curr_item
  )
  $bookshelves = $curr_item.where({$_.Name -eq 'bookshelves'}).Value
  $exclusiveShelf = $curr_item.where({$_.Name -eq 'exclusive-shelf'}).Value
  return $($bookshelves + $exclusiveShelf | Select-Object -Unique)
}

function Import-GoodreadsLibrary {
  param(
    [Parameter(Mandatory=$true)]
    [string]
    $goodreads_filepath,
    [Int32]
    $starting_index
  )
  #Convert the goodreads library export file from CSV into an obj
  $export = $(Get-Content $goodreads_filepath | convertfrom-csv)

  switch($starting_index){
    {$_ -ge $export.count}{
      $starting_index = $export.count - 1
    }
    {$_ -lt 0}{
      $starting_index = 0
    }
  }

  $booklogs = [System.Collections.ArrayList]::new()
  $total_items = $export.Count
  $stoping_index = $total_items-1
  $toProcess = $export[$starting_index..$stoping_index]
  $processed_items = 0
  # Go through each item and clean up these specific fields
  Write-InfoLog -MessageTemplate "Retrieved {TotalItems} from '{Path}'...will process {ToProcess} item(s)." -PropertyValues @($total_items, $goodreads_filepath, $toProcess.Count)
  foreach($entry in $toProcess){
    try{
      $booklogs += New-BookLogObject $entry
      $processed_items +=1
    }catch{
      Write-ErrorLog -MessageTemplate "Could not create a booklog for '{Title}'" -PropertyValues $entry.Title -ErrorRecord $_
    }
    $completion = $($processed_items/$toProcess.Count)*100
    Write-InfoLog -MessageTemplate "[{Complete:00.00}% Imported] Created booklog object for '{Title}'" -PropertyValues @(
      $completion, $entry.Title
    )
  }
  return $booklogs
}

function Merge-BookData {
  param(
    [PSCustomObject]
    $curr_item,
    [string]
    $queryType
  )

  $openlib_doc = search-openlib -curr_item $curr_item -query_type $queryType
  $gbook_vol = search-gbook -curr_item $curr_item -query_type $queryType
  $curr_item = Get-FormattedObject -curr_item $curr_item
  
  $combo_obj = $(
    Get-FlattenedObject -curr_fields $($openlib_doc + $gbook_vol + $curr_item)
  )

  return $combo_obj
}

function New-BookMetadata{
  param(
    [psobject]
    [Parameter(Mandatory=$true, ValueFromPipeline)]
    $merged_data
  )

  $filter = @(
    'Year Published',
    'Title',
    'thumbnail',
    'subject',
    'selfLink',
    'Read Count',
    'Publisher',
    'publishedDate',
    'Original Publication Year',
    'openlib-url',
    'Number of Pages',
    'My Rating',
    'lcc',
    'industryIdentifiers',
    'Exclusive Shelf',
    'description',
    'Date Read',
    'Date Added',
    'book-cover-url',
    'Bookshelves with positions',
    'Bookshelves',
    'Average Rating',
    'Author',
    'Additional Authors'
  )

  $filtered_obj = $merged_data.where({$_.Name -cin $filter})
  $filtered_obj.ForEach({$_.Name = $_.Name.toLower().replace(" ", "-")})
  $booklog_name = New-LogName -curr_item $filtered_obj
  
  $book_dict = @{}
  foreach($i in $filtered_obj){
    if($i.Name -eq 'industryidentifiers'){
        $ii_dict = @{}
        $i.Value.ForEach({
            $ii_dict[$_.type] = $_.identifier
        })
        $book_dict[$i.Name] = $ii_dict
    }
    elseif($i.Name -eq 'subject'){
      $book_dict['book-categories'] = $i.Value.Split(", ")
    }
    elseif($i.Name -eq 'bookshelves'){
      $book_dict['book-tags'] = $(New-BookTags $filtered_obj)
      $book_dict.remove('bookshelves')
    }
    elseif($i.Name -eq 'title'){
      $book_dict['book-title'] = $i.Value
    }
    elseif($i.Name -eq 'author'){
      $book_dict['book-author'] = $i.Value
    }
    elseif($i.Name -eq 'selflink'){
      $book_dict['gbook-url'] = $i.Value
    }
    else{
        $book_dict[$i.Name] = $i.Value
    }
  }
  $book_dict['cssClasses'] = @("wide-view","wide-table")
  $book_dict['tags'] = "log/book"

  return $(@($booklog_name, $book_dict))
}

function Build-BookLog {
  Param(
    [PSCustomObject]
    [Parameter(Mandatory=$true)]
    $booklog_metadata
  )

  $booklog_content =
@"
``````dataview
TABLE WITHOUT ID
("![]("+book-cover-url+")") as "Cover",
book-title as "Title",
book-author as "Author",
book-categories as "Categories"
WHERE file = this.file
``````
---
``````dataview
TABLE WITHOUT ID
book-tags as "Status",
avg-goodreads-rating as "Avg Rating",
my-rating as "My Rating"
WHERE file = this.file
``````
---
## Notes


"@

  $booklog_frontmatter = "---$([Environment]::NewLine)" + $(ConvertTo-Yaml $booklog_metadata) + "---$([Environment]::NewLine*2)"

  $total_content = [string]::Join('',@($booklog_frontmatter, $booklog_content))

  return $total_content
}
