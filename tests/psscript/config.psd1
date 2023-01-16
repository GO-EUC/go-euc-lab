# config.psd1
@{
    Severity=@('Error','Warning', 'Information')

    IncludeDefaultRules = $true

    # PSAvoidUsingInvokeExpression: Required for the citrix_site.ps1 library, as Invoke-Expression is used to execute command based on variables.
    # PSAvoidUsingWMICmdlet: Used for collecting the Citrix version.
    
    ExcludeRules=@('PSAvoidUsingInvokeExpression', 
    'PSAvoidUsingWMICmdlet') 
}
