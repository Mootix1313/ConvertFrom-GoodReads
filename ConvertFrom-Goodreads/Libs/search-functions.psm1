function Search-Gbook{
  param(
    #.Parameter An instance of the Booklog class
    [PSCustomObject]
    [Parameter(Mandatory = $true)]
    $curr_item,
    [string]
    $query_type = 'noisbn'
  )

  $gbook_api = 'https://www.googleapis.com/books/v1/volumes?projection=full&q='
  $q_string = ''

  switch($query_type){
    'isbn13'{
      $q_string = 
      [string]::join('+', @("isbn:$($curr_item.ISBN13)","intitle:$($curr_item.Title)"))
    }
    'isbn'{
      $q_string =
      [string]::join('+', @("isbn:$($curr_item.ISBN)","intitle:$($curr_item.Title)"))
    }
    'noisbn'{
      $q_string = [string]::join('+',
        @("inauthor:$($curr_item.Author)","intitle:$($curr_item.Title)")
      )
    }
  }

  $search_q = [string]::join('',@($gbook_api,$q_string));
  try{
    $gbook_obj = $(Invoke-WebRequest -Uri $search_q | convertfrom-json).items[0]
  }catch{
    $msg =
@"
Empty Gbook object for '$($curr_item.Title)'
[Search Query] '$search_q'
"@
    Write-ErrorLog -MessageTemplate $msg -PropertyValues @($curr_item.Title,$search_q) -ErrorRecord $_
    return $null
  }
  
  return $(Get-FormattedObject $gbook_obj)
}

function Search-Openlib {
  param(
    #.Parameter An instance of the Booklog class
    [PSCustomObject]
    [Parameter(Mandatory = $true)]
    $curr_item,
    [string]
    $query_type = 'noisbn'
  )

  $openlib_api = "https://openlibrary.org/search.json?type=work&q="
  $openlib_cover_api= "https://covers.openlibrary.org/b/id/"
  $openlib_base_url = "https://openlibrary.org"

  switch($query_type){
    'isbn13' {
      $q_string = [string]::join(" ", @($curr_item.Author,$curr_item.Title,$curr_item.ISBN13))
    }
    'isbn' {
      $q_string = [string]::join(" ", @($curr_item.Author,$curr_item.Title,$curr_item.ISBN))
    }
    'noisbn' {
      $q_string = [string]::join(" ", @($curr_item.Author,$curr_item.Title))
    }
  }

  $search_q = [string]::join('', @($openlib_api, $q_string))
  try{
    $openlib_doc = $(
      Invoke-WebRequest $search_q | `
        Select-Object -expandProperty Content | convertfrom-json) | `
        Select-Object -ExpandProperty docs | Select-Object -first 1
  }catch{
    $msg =
@"
Empty Openlibrary object for '{Title}'
[Search Query] '{Query}'
"@
    Write-ErrorLog -MessageTemplate $msg -PropertyValues @($curr_item.Title,$search_q) -ErrorRecord $_
    return $null
  }
  $cover_img = [string]::Join('',@($openlib_cover_api, $openlib_doc.cover_i,"-M.jpg"))
  $openlib_doc | Add-Member -MemberType NoteProperty -Name "openlib-url" -Value $([string]::Join('', @($openlib_base_url, $openlib_doc.key)))
  $openlib_doc | Add-Member -MemberType NoteProperty -Name "book-cover-url" -Value $cover_img

    return $(Get-FormattedObject $openlib_doc)
}