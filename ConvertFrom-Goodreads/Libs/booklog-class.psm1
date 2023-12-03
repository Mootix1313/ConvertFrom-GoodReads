class BookLog {
  [string] $logfilename
  [pscustomobject] $metadata
  [string] $raw_log

  <# Constructors #>
  BookLog ([pscustomobject] $GoodreadsRow){
    $this.initialize_log($GoodreadsRow)
  }
  BookLog (){
    $this.initialize_log()
  }
  hidden initialize_log(){
    $this.logfilename = 'tbd'
  }
  <#Hidden helper functions#>
  hidden initialize_log([PSCustomObject] $GoodreadsRow){
    $queryType = $(
      if ($GoodreadsRow.ISBN13) { 'isbn13' }
      elseif ($GoodreadsRow.ISBN) { 'isbn' }
      else { 'noisbn' }
    )
    $GoodreadsRow.'Additional Authors' = [regex]::split($GoodreadsRow.'Additional Authors',", ")
    $GoodreadsRow.'Date Added' = [regex]::replace($GoodreadsRow.'Date Added',"/","-")
    $GoodreadsRow.Bookshelves = [regex]::split($GoodreadsRow.Bookshelves,", ")
    $GoodreadsRow.'Bookshelves with positions' = [regex]::split($GoodreadsRow.'Bookshelves with positions',", ")
    $GoodreadsRow.ISBN13 = [regex]::replace($GoodreadsRow.ISBN13,'[="]','')
    $GoodreadsRow.ISBN = [regex]::replace($GoodreadsRow.ISBN, '[="]', '')
    $curr_metadata = New-BookMetadata -merged_data $(Merge-BookData -curr_item $GoodreadsRow -queryType $queryType)

    $this.logfilename = $curr_metadata[0]
    $this.metadata += $curr_metadata[1]
    $this.raw_log = Build-BookLog $this.metadata
  }
}

function New-BookLogObject{
  param(
    [pscustomobject] $GoodreadsRow
  )
  $new_log = $null
  try{
    $new_log = [BookLog]::new($GoodreadsRow)
  }
  catch {
    Write-FatalLog -MessageTemplate "Could not create new Booklog instance for {Title}" -PropertyValues $GoodreadsRow.Title -ErrorRecord $_
    return $new_log
  }
  
  return $new_log
}