function Start-GoodreadsLogging {
  param(
    [ValidateSet('both','file','console')]
    [string]
    $type
  )
  $import_gooreadslog=$(
    New-Logger
    |Add-EnrichWithErrorRecord `
    |Add-EnrichWithExceptionDetails
  )
  switch($type){
    'both'{
      Add-SinkConsole `
      -Theme $([Serilog.Sinks.SystemConsole.Themes.AnsiConsoleTheme]::Code) `
      -LoggerConfig $import_gooreadslog > $null

      Add-SinkFile `
        -Path "$($pwd)/ConvertFrom-Goodreads_$([datetime]::Now.Ticks).log"`
        -FlushToDiskInterval $([timespan]::FromSeconds(15)) `
        -LoggerConfig $import_gooreadslog > $null
    }
    'file'{
      Add-SinkFile `
        -Path "$($pwd)/ConvertFrom-Goodreads_$([datetime]::Now.Ticks).log"`
        -FlushToDiskInterval $([timespan]::FromSeconds(15)) `
        -LoggerConfig $import_gooreadslog > $null
    }
    'console'{
      Add-SinkConsole `
        -Theme $([Serilog.Sinks.SystemConsole.Themes.AnsiConsoleTheme]::Code)`
        -LoggerConfig $import_gooreadslog > $null
    }
  }
  Start-Logger -LoggerConfig $import_gooreadslog
}
