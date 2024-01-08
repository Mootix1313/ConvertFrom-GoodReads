using module ../Types/ConvertFromGoodReads.Types.psm1
function New-BookLog{
  [OutputType([BookLog])]
  param(
    [pscustomobject]
    $GoodreadsRow
  )
  try{
    return [BookLog]::new($GoodreadsRow)
  }
  catch {
    Write-ErrorLog `
      -MessageTemplate "Could not create BookLog instance for {Title}" `
      -PropertyValues $GoodreadsRow.Title `
      -ErrorRecord $_
    return $null
  }
}
