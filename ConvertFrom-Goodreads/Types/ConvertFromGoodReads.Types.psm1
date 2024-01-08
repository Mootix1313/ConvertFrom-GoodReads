using namespace System;
using namespace System.Management.Automation;
using namespace System.Collections.Generic;

class BookMetadata {
  [List[string]] $bkAuthors = @()
  [pscustomobject] $bkIdens = @{
    'isbn'='';
    'isbn13'='';
    'lcc_sort'='';
    'dcc_sort'='';
  }
  [pscustomobject] $bkAvgRatings = @{
    'openlib'='';
    'goodreads'='';
    'gbook'=''
  }
  [pscustomobject] $bkPubDates = @{
    'year-published'='';
    'org-pub-year'=''
  }
  [pscustomobject] $bkURLs = @{
    'openlib'='';
    'gbook'='';
    'goodreads'='';
  }
  [pscustomobject] $readerStats = @{
    'date-read'='';
    'date-added'='';
    'read-count'='';
    'my-rating'='';
  }
  [pscustomobject] $bkCover = @{
    'ol'='';
    'gb'=''
  }
  [SortedSet[string]]$bkCategories = @()
  [SortedSet[string]]$bkStatus = @()
  [string[]] $cssClasses=@("wide-view","wide-table")
  [string] $tags="log/book"
  [string] $created = ''
  [string] $modified = ''
  [string] $bkDescr = ''
  [string] $bkQueryTitle = ''
  [string] $bkTitle = ''
  [string] $bkPublisher = ''
  [string] $bkPageCnt = ''

  BookMetadata(){ }
  BookMetadata($GoodreadsRow){
    $this.Init($GoodreadsRow)
  }
  hidden Init($GoodreadsRow){
    $this.bkTitle = $GoodreadsRow.Title
    $this.bkURLs.goodreads = $(
      "{0}{1}" -f @($global:goodreads_url,$GoodreadsRow.'Book Id'))
    $this.bkQueryTitle = Format-Title $GoodreadsRow.Title
    $this.bkAuthors += $GoodreadsRow.Author
    $this.bkAuthors += [regex]::split($GoodreadsRow.'Additional Authors',", ")
    $this.bkAvgRatings.goodreads = $GoodreadsRow.'Average Rating'
    $this.readerStats.'my-rating' = $GoodreadsRow.'My Rating'
    $this.readerStats.'date-added' = [regex]::replace(
      $GoodreadsRow.'Date Added',"/","-"
    )
    $this.readerStats.'date-read' = $GoodreadsRow.'Date Read'
    $this.readerStats.'read-count' = $GoodreadsRow.'Read Count'
    $this.bkPubDates.'year-published' = $GoodreadsRow.'Year Published'
    $this.bkPubDates.'org-pub-year' = $GoodreadsRow.'Original Publication Year'
    $this.bkPublisher = $GoodreadsRow.'Publisher'
    $this.bkPageCnt = $GoodreadsRow.'Number of Pages'
    $this.bkStatus += Get-BookStatus $GoodreadsRow
    $this.bkIdens.isbn13 = Update-ISBN $GoodreadsRow.ISBN13
    $this.bkIdens.isbn = Update-ISBN $GoodreadsRow.ISBN
    $this.created = [datetime]::Now.ToString($global:datetimefmt)
  }
}

class BookQuery {
  [PSCustomObject] $gbqueries
  [PSCustomObject] $olqueries
  [PSCustomObject] $results

  BookQuery(){ }
  BookQuery([BookMetadata] $metadata){
    $this.Init($metadata)
  }

  hidden Init([pscustomobject] $metadata){
    $this.gbqueries = (
      New-SearchQueries `
        -uri_type 'gbook' `
        -metadata $metadata
    )
    $this.olqueries = (
      New-SearchQueries `
        -uri_type 'openlib' `
        -metadata $metadata
    )
    $this.results=@{
      gb='';
      ol='';
    }
  }
}

class BookLog {
  [BookMetadata] $metadata
  [BookQuery] $query_items
  [string] $logfilename
  [string] $raw_log
  [bool] $built = $false

  <# Constructors #>
  BookLog (){}
  BookLog($GoodreadsRow){
    $this.Init($GoodreadsRow)
  }

  hidden Init ($GoodreadsRow){
    <#
      - Initialize book's $metadata based on goodreads data.
      - Create an output filename based on goodreads data.
      - Setup structure to query book databases
      - Pull everything together, and write it to a file.
    #>
    $this.metadata = New-BookMetadata $GoodreadsRow
    $this.query_items = New-BookQuery $this.metadata
    $this.logfilename = New-LogName $GoodreadsRow
    #$this.raw_log = Build-BookLog $this
  }
}
