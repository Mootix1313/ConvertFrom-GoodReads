#
# Module manifest for module 'ConvertFrom-GoodReads'
#
# Generated by:   mootix1313
# Generated on:   29 November 2023
# Updated on:    04 January 2023

@{

# Script module or binary module file associated with this manifest.
RootModule = 'ConvertFrom-GoodReads'

# Version number of this module.
ModuleVersion = '0.0.13'

# Supported PSEditions
CompatiblePSEditions = @('Core', 'Desktop')

# ID used to uniquely identify this module
GUID = '61078192-0405-48f4-824f-543d251407d3'

# Author of this module
Author = 'mootix1313'

# Copyright statement for this module
Copyright = '(c) mootix1313. All rights reserved.'

# Description of the functionality provided by this module
Description = 'A module to assist converting a Goodreads library export file (csv) into individual markdown files, for each book within the CSV file, to be incorporated into an Obsidian Vault.'

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @(
  "$PSScriptRoot/Types/ConvertFromGoodReads.BookMetadata.Types.ps1xml",
  "$PSScriptRoot/Types/ConvertFromGoodReads.BookQuery.Types.ps1xml",
  "$PSScriptRoot/Types/ConvertFromGoodReads.BookLog.Types.ps1xml"
)

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @(
  "$PSScriptRoot/Formats/ConvertFromGoodReads.Format.ps1xml"
)

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @(
  "$PSScriptRoot/Types/ConvertFromGoodReads.Types.psm1",
  "$PSScriptRoot/Functions/bookdata.psm1",
  "$PSScriptRoot/Functions/booklog.psm1",
  "$PSScriptRoot/Functions/bookmetadata.psm1",
  "$PSScriptRoot/Functions/bookquery.psm1",
  "$PSScriptRoot/Functions/session-logging.psm1",
  "$PSScriptRoot/Functions/utilities.psm1",
  "$PSScriptRoot/Functions/webrequests.psm1"
)

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
  'Build-BookLog',
  'ConvertFrom-GoodReads',
  'Get-BookQueryResults',
  'Format-FrontMatter',
  'Format-GBookResp',
  'Format-OpenlibResp',
  'Format-Title',
  'Get-BookStatus',
  'Get-FlattenedObject',
  'Get-QueryType',
  'Import-GoodreadsLibrary',
  'Invoke-GbookSearch',
  'Invoke-OpenlibSearch',
  'Limit-PropertiesByFilter',
  'Limit-PropertiesByMemberType',
  'Limit-PropertiesByName',
  'Merge-BookData',
  'New-BookLog',
  'New-BookMetadata',
  'New-BookQuery',
  'New-LogName',
  'New-SearchQueries',
  'Start-GoodreadsLogging',
  'Update-ISBN'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
#AliasesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

  PSData = @{

      # Tags applied to this module. These help with module discovery in online galleries.
      Tags = @(
        'obsidian',
        'goodreads',
        'powershell',
        'powershell-module'
      )

      # A URL to the license for this module.
      LicenseUri = 'https://raw.githubusercontent.com/Mootix1313/ConvertFrom-GoodReads/main/LICENSE'

      # A URL to the main website for this project.
      ProjectUri = 'https://raw.githubusercontent.com/Mootix1313/ConvertFrom-GoodReads'

      # A URL to an icon representing this module.
      # IconUri = ''

      # ReleaseNotes of this module
      # ReleaseNotes = ''

      # Prerelease string of this module
      # Prerelease = ''

      # Flag to indicate whether the module requires explicit user acceptance for install/update/save
      #RequireLicenseAcceptance = $true

      # External dependent modules of this module
      ExternalModuleDependencies = @(
        "$PSScriptRoot/Libs/PoShLog",
        "$PSScriptRoot/Libs/PoShLog.Enrichers",
        "$PSScriptRoot/Libs/powershell-yaml"
      )

  } # End of PSData hashtable

} # End of PrivateData hashtable

}