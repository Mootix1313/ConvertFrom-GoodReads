function Import-Assemblies{
  $modules_toimport = @(
    'PoShLog/2.2.0/PoShLog.psm1',
    'PoShLog.Enrichers/1.0.0/PoShLog.Enrichers.psm1',
    'powershell-yaml/0.4.7/powershell-yaml.psm1',
    'booklog-class.psm1',
    'logging.psm1',
    'manipulate-data.psm1',
    'search-functions.psm1'
  )

  foreach($module in $modules_toimport){
    Import-Module $module -ErrorAction 'silentlycontinue'
  }
  $PSStyle.Progress.View = 'Classic'
}