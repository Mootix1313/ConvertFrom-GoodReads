<#
  .Synopsis
    Automates conversion of goodreads_library_export.csv to markdown files for each item in the file.

  .Description
    A module to assist converting a Goodreads library export file (csv) into individual markdown files, for each book within the CSV file, to be incorporated into an Obsidian Vault.
  
  .Notes
    Each booklog's metadata can have up to three sources:
      1. The goodreads_library_export.csv file
      2. A Book Volume object returned from a Google Books query
      3. A Works object returned from an Openlibrary query

    The sources are merged and distilled into a [BookLog] instance, which contains:
      - The distilled book metadata
      - The name of the book's log file
      - The raw log contents to be written to a file

    Currently, the log contents are made up of the front matter (dynamic) and the book content (static). This currently fits my setup, but can easily be modified to fit yours:
    
    @"
      ---
      $(ConvertTo-Yaml booklog.metadata)
      ---

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

  .Parameter goodreads_filepath
    The path\to\goodreads_library_export.csv.

  .Parameter output_filepath
    The location to save each individual markdown file.

  .Parameter starting_index
    Index of the Goodreads library to begin conversion from.

  .Parameter logging
    Toggles logging to the console during execution.

  .Example
    # Begin conversion of goodreads library export, save output to current working directory.
    ConvertFrom-GoodReads "path\to\goodreads_library_export.csv"

  .Example
    # Begin conversion of goodreads library export, save output to specified location.
    ConvertFrom-GoodReads `
      -goodreads_filepath "path\to\goodreads_library_export.csv" `
      -output_filepath "path\to\output\folder"

  .Example
    # Same concept as Example #2, but will output activity to console host
    ConvertFrom-GoodReads `
      -goodreads_filepath "path\to\goodreads_library_export.csv" `
      -output_filepath "path\to\output\folder" `
      -logging
    
    [22:54:21 INF] Retrieved 242 from './goodreads_library_export.csv'...will process 242 item(s).
    [22:54:22 INF] [00.41% Imported] Created booklog object for 'The Wicked + The Divine Deluxe Edition: Year Three'
    [22:54:23 INF] [00.83% Imported] Created booklog object for 'Classic Horror Stories'
            ...
    [23:07:36 INF] [60.74% Imported] Created booklog object for 'HOUSE OF LEAVES.'
    [23:07:37 INF] [61.16% Imported] Created booklog object for 'Lord of the Flies'
    [23:07:38 INF] [61.57% Imported] Created booklog object for 'River Marked (Mercy Thompson, #6)'
    [23:07:38 INF] [61.98% Imported] Created booklog object for 'Cloaked'
    [23:07:39 INF] [62.40% Imported] Created booklog object for 'The Alienist (Dr. Laszlo Kreizler, #1)'
    [23:07:40 INF] [62.81% Imported] Created booklog object for 'The Lottery and Other Stories'
    [23:07:41 INF] [63.22% Imported] Created booklog object for 'A Canticle for Leibowitz (St. Leibowitz, #1)'
            ...
    [23:09:22 INF] [98.76% Processed] Wrote log for 'Romeo and Juliet' to './Reading/1597-William_Shakespeare-Romeo_and_Juliet.md'.
    [23:09:22 INF] [99.17% Processed] Wrote log for 'Where the Sidewalk Ends' to './Reading/1974-Shel_Silverstein-Where_the_Sidewalk_Ends.md'.
    [23:09:22 INF] [99.59% Processed] Wrote log for 'The Great Gatsby' to './Reading/1925-F._Scott_Fitzgerald-The_Great_Gatsby.md'.
    [23:09:22 INF] [100.00% Processed] Wrote log for 'To Kill a Mockingbird' to './Reading/1960-Harper_Lee-To_Kill_a_Mockingbird.md'.
    [23:09:22 INF] Took 04m 42.97s to process 242 item(s).

    .Example
    # Same concept as Example #3, but will start conversion from the provided index, 240.
    ConvertFrom-GoodReads `
      -goodreads_filepath "path\to\goodreads_library_export.csv" `
      -output_filepath "path\to\output\folder" `
      -logging
      -starting_index 240

    [22:50:10 INF] Retrieved 242 from './goodreads_library_export.csv'...will process 2 item(s).
    [22:50:14 INF] [50.00% Imported] Created booklog object for 'The Great Gatsby'
    [22:50:16 INF] [100.00% Imported] Created booklog object for 'To Kill a Mockingbird'
    [22:50:16 INF] [50.00% Processed] Wrote log for 'The Great Gatsby' to './Reading/1925-F._Scott_Fitzgerald-The_Great_Gatsby.md'.
    [22:50:16 INF] [100.00% Processed] Wrote log for 'To Kill a Mockingbird' to './Reading/1960-Harper_Lee-To_Kill_a_Mockingbird.md'.
    [22:50:16 INF] Took 00m 05.7s to process 2 item(s).

    .Example
    # If there are errors along the way, they will be conveyed to the user when logging is turned on.
    ConvertFrom-GoodReads `
      -goodreads_filepath "path\to\goodreads_library_export.csv" `
      -output_filepath "path\to\output\folder" `
      -logging
    
    [[23:04:39 INF] Retrieved 242 from './goodreads_library_export.csv'...will process 242 item(s).
    [23:04:40 ERR] Empty Gbook object for 'The Wicked + The Divine Deluxe Edition: Year Three'
    [Search Query] 'https://www.googleapis.com/books/v1/volumes?projection=full&q=isbn:9781534308572+intitle:The Wicked + The Divine Deluxe Edition: Year Three'
    ┌───────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │ CategoryInfo          │ InvalidOperation: (:) [], RuntimeException                                                                              │
    ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │ FullyQualifiedErrorId │ NullArray                                                                                                               │
    ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │ ScriptStackTrace      │ at Search-Gbook, /Users/<you>/Downloads/ConvertFrom-GoodReads/Libs/search-functions.psm1: line 32                 │
    │                       │ at Merge-BookData, /Users/<you>/Downloads/ConvertFrom-GoodReads/Libs/manipulate-data.psm1: line 125               │
    │                       │ at initialize_log, /Users/<you>/Downloads/ConvertFrom-GoodReads/Libs/booklog-class.psm1: line 29                  │
    │                       │ at BookLog, /Users/<you>/Downloads/ConvertFrom-GoodReads/Libs/booklog-class.psm1: line 8                          │
    │                       │ at New-BookLogObject, /Users/<you>/Downloads/ConvertFrom-GoodReads/Libs/booklog-class.psm1: line 43               │
    │                       │ at Import-GoodreadsLibrary, /Users/<you>/Downloads/ConvertFrom-GoodReads/Libs/manipulate-data.psm1: line 103      │
    │                       │ at ConvertFrom-GoodReads<Begin>, /Users/<you>/Downloads/ConvertFrom-GoodReads/ConvertFrom-GoodReads.psm1: line 72 │
    │                       │ at <ScriptBlock>, <No file>: line 1                                                                                     │
    └───────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
    System.Management.Automation.RuntimeException: Cannot index into a null array.
      at System.Management.Automation.ExceptionHandlingOps.CheckActionPreference(FunctionContext funcContext, Exception exception)
      at System.Management.Automation.Interpreter.ActionCallInstruction`2.Run(InterpretedFrame frame)
      at System.Management.Automation.Interpreter.EnterTryCatchFinallyInstruction.Run(InterpretedFrame frame)
      at System.Management.Automation.Interpreter.EnterTryCatchFinallyInstruction.Run(InterpretedFrame frame)
  [23:04:40 INF] [00.41% Imported] Created booklog object for 'The Wicked + The Divine Deluxe Edition: Year Three'
            ...
#>
function ConvertFrom-GoodReads{
  [CmdletBinding()]
  param(
    [string]
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
    $goodreads_filepath,
    [string]
    [ValidateScript({ Test-Path $_ })]
    $output_filepath = ".",
    [int32]
    $starting_index=0,
    [switch]
    $logging
  )
  Begin{
    Import-Assemblies
    if($logging){
      try{
        $startTime = [datetime]::Now
        Start-GoodreadsLogging
      }catch{
        Write-Error "[!] Couldn't start PoSh Logging Session."
        Get-PSCallStack
      }
    }
    $export = $(
      Import-GoodreadsLibrary `
        -goodreads_filepath $goodreads_filepath `
        -starting_index $starting_index
    )
    $total_items = $export.Count
    $processed_items = 0
  }Process{
    foreach($booklog in $export){
      $log_outpath = $([System.IO.Path]::Join($output_filepath,$booklog.logfilename))
      try{
        Out-File -LiteralPath $log_outpath -InputObject $booklog.raw_log -Encoding utf8 -Force
        $processed_items +=1
      }catch{
        Write-ErrorLog `
          -MessageTemplate "[!] Couldn't build log for '{Title}'" `
          -PropertyValues $($booklog.metadata['book-title'])
          -ErrorRecord $_
        continue
      }
      $completion = $($processed_items/$total_items)*100
      Write-InfoLog `
        -MessageTemplate "[{Processed:00.00}% Processed] Wrote log for '{Title}' to '{log_outpath}'." `
        -PropertyValues @(
          $completion,$booklog.metadata['book-title'],$log_outpath
        )
    }
  }End{
    if($logging){
      $stopTime = [datetime]::Now
      $duration = $stopTime - $startTime
      Write-InfoLog -MessageTemplate "Took {duration} to process {processed_items} item(s)." -PropertyValues @(
        $duration.toString("mm\m\ ss\.FF\s"),
        $processed_items
      )
      Close-Logger
    }
  }
}