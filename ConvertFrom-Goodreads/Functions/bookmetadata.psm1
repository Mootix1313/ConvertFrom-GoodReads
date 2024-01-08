using namespace System;
using namespace System.Collections.Generic;
using module ../Types/ConvertFromGoodReads.Types.psm1

function Format-Title {
  [OutputType([string])]
  param(
    [string]
    $dirty_title
  )
  $reg_split = $regex_utils.parens
  $reg_rem = $regex_utils.pound
  $clean_title=$reg_split.split($dirty_title).TrimStart().TrimEnd()
  return $reg_rem.Replace($clean_title,'')
}

function New-LogName {
  [OutputType([string])]
  param(
    [pscustomobject]
    $GoodreadsRow
  )
  $_nvalidChars = [regex]::new(
    "[$([string]::Join('',[System.IO.Path]::GetInvalidFileNameChars()))]",
    @('Compiled', 'Singleline'),
    [timespan]::FromSeconds(3)
  )
  $opy = $GoodreadsRow.'Original Publication Year'
  $yp = $GoodreadsRow.'Year Published'
  $author = $GoodreadsRow.'Author'
  $title = $GoodreadsRow.'Title'

  $name_seeds = @(
    $($opy -ilike $null ? $yp : $opy).replace(" ","_"),
    $author.replace(" ", "_"),
    $title.replace(" ", "_")
  )

  return $_nvalidChars.Replace(
    $([string]::Join('-', $name_seeds)+".md"),'')
}

function Get-BookStatus {
  [OutputType([SortedSet[string]])]
  Param(
    [pscustomobject]
    $GoodreadsRow
  )
  $bkshelves = $([regex]::split($GoodreadsRow.Bookshelves,", "))+$([regex]::split($GoodreadsRow.'Bookshelves with positions',", "))
  $exshelf = $GoodreadsRow.'Exclusive Shelf'
  $statuses = [SortedSet[string]]::new()
  @($bkshelves,$exshelf) | ForEach-Object{
    foreach($shelf in $_){
      if($_ -notlike $null){
        $statuses.Add($_)>$null;
      }
    }
  }
  return $statuses
}

function Update-ISBN{
  [OutputType([string])]
  param(
    [string]
    $isbn_string
  )
  $bad_isbn_chars=[regex]::new(
    '[="]',
    @('Compiled'),
    [timespan]::FromSeconds(3)
  )
  $cleaned_isbn = $bad_isbn_chars.replace($isbn_string,'')

  if(Confirm-ISBN $cleaned_isbn){
    return $cleaned_isbn
  }

  return ''
}

function Confirm-ISBN {
  [OutputType([bool])]
  [CmdletBinding(<#
  .SYNOPSIS
    Quickly determines if an ISBN-10 or -13 is valid or not.
  .NOTES
    - ISBN10 format reference: https://isbn-information.com/the-10-digit-isbn.html
    - ISBN13 format reference: https://isbn-information.com/check-digit-for-the-13-digit-isbn.html
  #>
  )]
  param(
    [string]
    $isbn
  )
  switch($isbn.Length){
    10{
      $currSum = 0
      $weights = 10..1;
      foreach($i in 0..9){
        if($isbn[$i] -imatch "X"){
          $currSum += 10*$weights[$i]
        }else{
          $currSum += [int]::Parse($isbn[$i])*$weights[$i]
        }
      }
      if($currSum%11 -ne 0){
        return $false
      }
      return $true
    }
    13{
      $checkValue = [int]::Parse($isbn[12])
      $currSum = 0
      foreach($i in 0..11){
        if($i % 2 -eq 0){
          $currSum += [int]::Parse($isbn[$i])*1
        }else{
          $currSum += [int]::Parse($isbn[$i])*3
        }
      }
      if($(10-$currSum%10) -ne $checkValue){
        return $false
      }
      return $true
    }
    default{
      return $false
    }
  }
}

function New-BookMetadata {
  [OutputType([BookMetadata])]
  param(
    [pscustomobject]
    $GoodreadsRow
  )
  try{
    return [BookMetadata]::new($GoodreadsRow)
  }catch{
    Write-ErrorLog `
      -MessageTemplate "Could not create BookMetadata instance for {Title}" `
      -PropertyValues $GoodreadsRow.Title `
      -ErrorRecord $_
    return $null
  }
}
