# ConvertFrom-GoodReads

A powershell module to automate the conversion of a Goodreads library export file into individual markdown files, for each book, to use within an Obsidian vault. Inspired by [jag3773's gist](https://gist.github.com/jag3773/c65afd53944815efe495dae798327021).

---

## Usage

### Downloading

Grab a copy of the repository, either by cloning or downloading the zip, and save it to a convenient location:

```powershell
PS> git clone "https://github.com/Mootix1313/ConvertFrom-GoodReads.git"
PS> Get-ChildItem

        Directory: /Users/mootix1313/Downloads


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d----         12/1/2023  12:13 AM                ConvertFrom-GoodReads
```

**or**

```powershell
PS> Invoke-WebRequest "https://github.com/Mootix1313/ConvertFrom-GoodReads/archive/refs/heads/main.zip" -OutFile main.zip
PS> 7z x ./main.zip
PS> gci

       Directory: /Users/mootix1313/Downloads

Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d----         12/1/2023  12:13 AM                ConvertFrom-GoodReads-main
```

### Importing

If you cloned the repository:

```powershell
PS> Import-Module ./ConvertFrom-GoodReads
```

If you downloaded **main.zip**:

```powershell
PS> Import-Module ./ConvertFrom-GoodReads-main/ConvertFrom-GoodReads.psd1
```

### Execution

```powershell
ConvertFrom-GoodReads `
    -goodreads_filepath <String> `
    -output_filepath <String> `
    -starting_index <Int32> `
    -logging <CommonParameters> `
```

### Parameter Descriptions

**goodreads_filepath**: "path\to\goodreads_library_export.csv".
>
>|         |      |
>|:---------|:------|
>|Required?                    |true|
>|Position?                    |1|
>|Default value                |n/a|
>|Accept pipeline input?       |false|
>|Accept wildcard characters?  |false|

**output_filepath**: "path\to\output_dir".

>|         |      |
>|:---------|:------|
>|Required? | false |
>|Position? | 2 |
>|Default value | "." |
>|Accept pipeline input?| false|
>|Accept wildcard characters?| false|

**starting_index**: Zero-based index of the Goodreads CSV to begin processing from.

>|         |      |
>|:---------|:------|
>|Required?| false|
>|Position? | 3 |
>|Default value| 0 |
>|Accept pipeline input? | false |
>|Accept wildcard characters?|false|

**logging**: toggles console output during execution, otherwise there's no output while processing.

>|         |      |
>|:---------|:------|
>|Required?|                    false|
>|Position? |                    named|
>|Default value |                False|
>|Accept pipeline input?|       false|
>|Accept wildcard characters?|  false|

### Examples

#### EXAMPLE 1: Begin conversion of goodreads library export, save output to current working directory

**Note:** running this way should not produce output to the Host.

```powershell
PS> ConvertFrom-GoodReads "path\to\goodreads_library_export.csv"`
```

#### EXAMPLE 2: Begin conversion of goodreads library export, save output to specified location

**Note:** running this way should not produce output to the Host.

```powershell
PS> ConvertFrom-GoodReads `
    -goodreads_filepath "path\to\goodreads_library_export.csv" `
    -output_filepath "path\to\output\folder"
```

#### EXAMPLE 3: Same concept as Example #2, but will output activity to console host

```powershell
PS> ConvertFrom-GoodReads `
    -goodreads_filepath "path\to\goodreads_library_export.csv" `
    -output_filepath "path\to\output\folder" `
    -logging
```

**Sample output:**

```powershell
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
```

#### EXAMPLE 4: Same concept as Example #3, but will start conversion from the provided index, 240

```powershell
PS> ConvertFrom-GoodReads `
  -goodreads_filepath "path\to\goodreads_library_export.csv" `
  -output_filepath "path\to\output\folder" `
  -logging
  -starting_index 240
```

**Sample output:**

```powershell
[22:50:10 INF] Retrieved 242 from './goodreads_library_export.csv'...will process 2 item(s).
[22:50:14 INF] [50.00% Imported] Created booklog object for 'The Great Gatsby'
[22:50:16 INF] [100.00% Imported] Created booklog object for 'To Kill a Mockingbird'
[22:50:16 INF] [50.00% Processed] Wrote log for 'The Great Gatsby' to './Reading/1925-F._Scott_Fitzgerald-The_Great_Gatsby.md'.
[22:50:16 INF] [100.00% Processed] Wrote log for 'To Kill a Mockingbird' to './Reading/1960-Harper_Lee-To_Kill_a_Mockingbird.md'.
[22:50:16 INF] Took 00m 05.7s to process 2 item(s).
```

#### EXAMPLE 5: If there are errors along the way, they will output to the Host when logging is on

```powershell
PS> ConvertFrom-GoodReads `
  -goodreads_filepath "path\to\goodreads_library_export.csv" `
  -output_filepath "path\to\output\folder" `
  -logging
```

**Sample output:**

```powershell
[23:04:39 INF] Retrieved 242 from './goodreads_library_export.csv'...will process 242 item(s).
[23:04:40 ERR] Empty Gbook object for 'The Wicked + The Divine Deluxe Edition: Year Three'
[Search Query] 'https://www.googleapis.com/books/v1/volumes?projection=full&q=isbn:9781534308572+intitle:The Wicked + The Divine Deluxe Edition: Year Three'
┌───────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ CategoryInfo          │ InvalidOperation: (:) [], RuntimeException                                                                              │
├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ FullyQualifiedErrorId │ NullArray                                                                                                               │
├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ScriptStackTrace      │ at Search-Gbook, /Users/mootix1313/Downloads/ConvertFrom-GoodReads/Libs/search-functions.psm1: line 32                 │
│                       │ at Merge-BookData, /Users/mootix1313/Downloads/ConvertFrom-GoodReads/Libs/manipulate-data.psm1: line 125               │
│                       │ at initialize_log, /Users/mootix1313/Downloads/ConvertFrom-GoodReads/Libs/booklog-class.psm1: line 29                  │
│                       │ at BookLog, /Users/mootix1313/Downloads/ConvertFrom-GoodReads/Libs/booklog-class.psm1: line 8                          │
│                       │ at New-BookLogObject, /Users/mootix1313/Downloads/ConvertFrom-GoodReads/Libs/booklog-class.psm1: line 43               │
│                       │ at Import-GoodreadsLibrary, /Users/mootix1313/Downloads/ConvertFrom-GoodReads/Libs/manipulate-data.psm1: line 103      │
│                       │ at ConvertFrom-GoodReads<Begin>, /Users/mootix1313/Downloads/ConvertFrom-GoodReads/ConvertFrom-GoodReads.psm1: line 72 │
│                       │ at <ScriptBlock>, <No file>: line 1                                                                                     │
└───────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
System.Management.Automation.RuntimeException: Cannot index into a null array.
  at System.Management.Automation.ExceptionHandlingOps.CheckActionPreference(FunctionContext funcContext, Exception exception)
  at System.Management.Automation.Interpreter.ActionCallInstruction`2.Run(InterpretedFrame frame)
  at System.Management.Automation.Interpreter.EnterTryCatchFinallyInstruction.Run(InterpretedFrame frame)
  at System.Management.Automation.Interpreter.EnterTryCatchFinallyInstruction.Run(InterpretedFrame frame)
[23:04:40 INF] [00.41% Imported] Created booklog object for 'The Wicked + The Divine Deluxe Edition: Year Three'
        ...
```

---

## Booklog Metadata and Raw Log Sources

### Metadata

Each booklog's metadata can have up to three sources:

  1. The goodreads_library_export.csv file
  2. A Book Volume object returned from a Google Books query
  3. A Works object returned from an Openlibrary query

The merged sources are distilled into a [BookLog] instance, which contains:

- The distilled book metadata
- The name of the book's log file
- The raw log contents for output

### Raw Log

Comprises front matter (dynamic) and the book content (static). The static content fits my setup, but can be [changed](https://github.com/Mootix1313/ConvertFrom-GoodReads/blob/2fb3fcffcce4bed18ce7fdffa98d20f22324a995/Libs/manipulate-data.psm1#L208C1-L209C1) as needed:

```powershell
$raw_log = 
@"
---
$(ConvertTo-Yaml booklog.metadata)
---

~~~dataview
TABLE WITHOUT ID
("![]("+book-cover-url+")") as "Cover",
book-title as "Title",
book-author as "Author",
book-categories as "Categories"
WHERE file = this.file
~~~
---
~~~dataview
TABLE WITHOUT ID
book-tags as "Status",
avg-goodreads-rating as "Avg Rating",
my-rating as "My Rating"
WHERE file = this.file
~~~
---

##Notes


"@
```
