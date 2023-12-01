function Start-GoodreadsLogging{
  $import_gooreadslog = $(
    New-Logger `
    |Add-EnrichWithErrorRecord `
    |Add-EnrichWithExceptionDetails `
    |Add-SinkConsole -Theme $([Serilog.Sinks.SystemConsole.Themes.AnsiConsoleTheme]::Code) `
    <#|Add-SinkFile -Path "$($pwd)/ConvertFrom-Goodreads_$([datetime]::Now.Ticks).log" -FlushToDiskInterval $([timespan]::FromSeconds(15))#>
  )
  Start-Logger -LoggerConfig $import_gooreadslog
}