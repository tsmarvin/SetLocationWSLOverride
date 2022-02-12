# Module manifest for module 'SetLocationWSLOverride'
@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'SetLocationWSLOverride.psm1'

    # Version number of this module.
    ModuleVersion = '1.1.0'

    # Supported PSEditions
    CompatiblePSEditions = 'Core'

    # ID used to uniquely identify this module
    GUID  = '635ca3fc-b6ce-4435-a62c-b2aef8f88ce1'

    # Author of this module
    Author = 'Taylor Marvin'

    # Description of the functionality provided by this module
    Description = 'Replaces the Set-Location cmdlet to allow pasting windows paths in your wsl session.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = 'Set-LocationWSLOverride', 'Update-WindowsDrivesList'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = '*'

    # List of all files packaged with this module
    FileList = 'SetLocationWSLOverride.psd1', 'SetLocationWSLOverride.psm1', 'LICENSE'

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @( 'WSL', 'Set-Location', 'CD' )

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/tsmarvin/SetLocationWSLOverride/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/tsmarvin/SetLocationWSLOverride'
        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
