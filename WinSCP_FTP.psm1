<#$scriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
    Set-Location -Path $scriptFolder
    if (Test-Path -Path "$scriptFolder\WinSCPnet.dll" -PathType Leaf) {
    Add-Type -Path "$scriptFolder\WinSCPnet.dll"
    }
    else {
    Write-Host "You need the WinSCP automation DLL WINSCPnet.dll" -ForegroundColor Red -BackgroundColor Yellow
    }
#>
function Send-FTP{
  <#
      .SYNOPSIS
      Uploads a File or Directory to remote FTP Server

      .DESCRIPTION
      Function uploads file[s] and or directory[ies] to a ftp site and stores it to a given remote path

      .EXAMPLE
      Send-FTP -site 'ftp.avm.de' -source 'c:\temp\*.*' -dest '/fritzbox/fritzbox-7530/other/recover/'
      Uploads anonymously all files and directories beginning at c:\temp to remote ftp folder ../recover/

      .EXAMPLE
      Send-FTP -site 'ftp.avm.de' -source 'c:\temp\myfile.txt' -dest '/myftp/recover_de.txt' 
      Uploads anonymously local file myfile.txt and uploads it to remote ftp filepath /myftp/recover_de.txt 

      .NOTES
      
      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Get-Files

      .INPUTS
      -user            [<ftp username if ommited anonymous will be used>]
      -pass            [<ftp password if ommited anonymous will be used>]
      -site            <ftp server adress>
      -port            [<Use specific FTP(s) Port>]
      -source          <source directory>
      -dest            <destination directory>
      -timeout         [<seconds>]
      -secure          [<use FTP over SSL>]
      -activemode      [<use ftp(s) ative mode>]
      -trustAnyTLSCert [<ignore any SSL trust errors only in combination with switch secure>]
      -enablelog       [<enable logging>]

      .OUTPUTS
      Uploads binary file[s] or directories to FTP Server
  #>    
  param (
    [Parameter(Mandatory = $false, 
    ValueFromPipelineByPropertyName = $true)]
    [string]
    $user="anonymous",
    [Parameter(Mandatory = $false, 
    ValueFromPipelineByPropertyName = $true)]
    [string]
    $pass="anonymous",
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Enter the ftp server like ftp.avm.de')]
    [string]
    $site,
    [int]
    $Port=0,
    [SupportsWildcards()]
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Enter the source directory or filepath like c:\temp\* or c:\temp\myfile.txt')]
    [string]
    $source,
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Enter remote destination filepath or directory like /myftp/myfile.txt or /myftp/temp/')]
    [string]
    $dest,
    [int]
    $timeout=30,
    [switch]
    $secure=$false,
    [switch]
    $activemode=$false,
    [switch]
    $trustAnyTLSCert=$false,
    [switch]
    $enablelog=$false
  )
  $script:lastFileName = $Null
  try {
     
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions
    $sessionOptions.Protocol = [WinSCP.Protocol]::Ftp
    $sessionOptions.HostName = "$site"
    $sessionOptions.UserName = "$user"
    $sessionOptions.Password = "$pass"
    $sessionOptions.PortNumber = $Port
    $sessionOptions.Timeout = New-TimeSpan -Seconds $timeout
        
    if ($activemode) {
      $sessionOptions.FtpMode = [WinSCP.FtpMode]::Active
    }
    
    if ($secure) {
      $sessionOptions.FtpSecure = [WinSCP.FtpSecure]::Explicit
    }
    
    if($secure -and $trustAnyTLSCert) {
      $sessionOptions.GiveUpSecurityAndAcceptAnyTlsHostCertificate = $true
    } 
    try {  
      $session = New-Object WinSCP.Session
    
      # Write log
      if ($enablelog) {
        $Session.SessionLogPath = "$env:TEMP\ftp.log" 
      }
     
      $Success = @()
      $Failure = @()
      $filepaths = Get-ChildItem -Path $source -Recurse -ErrorAction SilentlyContinue |
      Where-Object {!$_.psIsContainer -eq $True} | ForEach-Object -Process {$_.FullName}
          
      $session.add_FileTransferProgress( { FileTransferProgress($_) } )
          
      # Connect
      $session.Open($sessionOptions)

      # Upload files
      $transferOptions = New-Object WinSCP.TransferOptions
      $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
          
      foreach ($filepath in $filepaths) {
        # Will continuously report progress of transfer
        $transferResult = $session.PutFiles("$filepath", "$dest", $False, $transferOptions)
        If ($transferResult.IsSuccess) {
          Write-Host -ForegroundColor Green ("$(Get-Date -f "dd.MM.yyyy hh:mm:ss") {0} was transferred to {1}." -f
          (Split-Path $FilePath -Leaf -Resolve), $dest)
          $Success += (Split-Path $FilePath -Leaf -Resolve)
        }
        Else {
          Write-Host -ForegroundColor Red ("$(Get-Date -f "dd.MM.yyyy hh:mm:ss") {0} was not transferred to {1}. Error: {2}." -f
          (Split-Path $FilePath -Leaf -Resolve), $dest, $transferResult.failures[0].Message -Replace '(?:\s|\r|\n)',' ') #THIS IS THE PART WHERE THE ERROR.MESSAGE IS BLANK
          $Failure += (Split-Path $FilePath -Leaf -Resolve)
        }   
      }
    }
    catch [WinSCP.SessionException] {
      Write-Host "Error: $($_.Exception.Message)"
      return 2
    }
    finally {
      # Terminate line after the last file (if any)
      if ($script:lastFileName -ne $Null) {
        Write-Host
      }  
      # Disconnect, clean up
      $session.Dispose()
    }
     

  }
  Catch {
      Write-Host ("Error: {0}" -f $_.Exception.Message)
      $Failure += (Split-Path $FilePaths -Leaf -Resolve)
  }
}

function Get-FTP{
  <#
      .SYNOPSIS
      Downloads a File or Directory to remote FTP Server

      .DESCRIPTION
      Function downloads file[s] and or directory[ies] to a ftp site and stores it to a given remote path

      .EXAMPLE
      Get-FTP -site 'ftp.avm.de' -source '/fritzbox/fritzbox-7530/other/recover/*' -dest 'c:\temp\' 
      Downloads anonymously all files and directories beginning at ftp folder ../recover/ and stores it in c:\temp

      .EXAMPLE
      Get-FTP -site 'ftp.avm.de' -source '/myftp/recover_de.txt' -Dest 'c:\temp\myfile.txt'
      Downloads anonymously remote file recover_de.txt and saves it to at local filepath c:\temp\myfile.txt 

      .NOTES
      
      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Get-Files

      .INPUTS
      -user            [<ftp username if ommited anonymous will be used>]
      -pass            [<ftp password if ommited anonymous will be used>]
      -site            <ftp server adress>
      -port            [<Use specific FTP(s) Port>]
      -source          <source directory>
      -dest            <destination directory>
      -timeout         [<seconds>]
      -secure          [<use FTP over SSL>]
      -activemode      [<use ftp(s) ative mode>]
      -trustAnyTLSCert [<ignore any SSL trust errors only together with switch secure>]
      -enablelog       [<enable logging>]

      .OUTPUTS
      Downloads binary file[s] or directories from FTP Server
  #>    
  param (
    [Parameter(Mandatory = $false, 
    ValueFromPipelineByPropertyName = $true)]
    [string]
    $user="anonymous",
    [Parameter(Mandatory = $false, 
    ValueFromPipelineByPropertyName = $true)]
    [string]
    $pass="anonymous",
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Enter the ftp server like ftp.avm.de')]
    [string]
    $site,
    [int]
    $Port=0,
    [SupportsWildcards()]
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Enter the remote source directory or filepath like /myftp/myfile.txt or /myftp/temp/')]
    [string]
    $source,
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Enter local destination filepath or directory like c:\temp\ or c:\temp\filename.txt')]
    [string]
    $dest,
    [int]
    $timeout=30,
    [switch]
    $secure=$false,
    [switch]
    $activemode=$false,
    [switch]
    $trustAnyTLSCert=$false,
    [switch]
    $enablelog=$false
  )
  $script:lastFileName = $Null
  try {
     
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions
    $sessionOptions.Protocol = [WinSCP.Protocol]::Ftp
    $sessionOptions.HostName = "$site"
    $sessionOptions.UserName = "$user"
    $sessionOptions.Password = "$pass"
    $sessionOptions.PortNumber = $Port
    $sessionOptions.Timeout = New-TimeSpan -Seconds $timeout
    
    if ($activemode) {
      $sessionOptions.FtpMode = [WinSCP.FtpMode]::Active
    }
    
    if ($secure) {
      $sessionOptions.FtpSecure = [WinSCP.FtpSecure]::Explicit
    }
    
    if($secure -and $trustAnyTLSCert) {
      $sessionOptions.GiveUpSecurityAndAcceptAnyTlsHostCertificate = $true
    } 
    try {  
      $session = New-Object WinSCP.Session
    
      # Write log
      if ($enablelog) {
        $Session.SessionLogPath = "$env:TEMP\ftp.log" 
      }
     
      $Success = @()
      $Failure = @()
          
      $session.add_FileTransferProgress( { FileTransferProgress($_) } )
          
      # Connect
      $session.Open($sessionOptions)

      # Upload files
      $transferOptions = New-Object WinSCP.TransferOptions
      $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
          
      # Will continuously report progress of transfer
      $transferResult = $session.GetFiles("$source", "$dest", $False, $transferOptions)
    
      # Stellt Ergebnisse des Übertragungsvorgangs dar
      $transferResult.Check()
 
      # Ausgabe der Ereignisse
      foreach ($transfer in $transferResult.Transfers) {
        If ($transferResult.IsSuccess) {
          Write-Host -ForegroundColor Green ("$(Get-Date -f "dd.MM.yyyy hh:mm:ss") {0} was transferred to {1}." -f $transfer.FileName, $dest)
        }
        Else {
          Write-Host -ForegroundColor Red ("$(Get-Date -f "dd.MM.yyyy hh:mm:ss") {0} was not transferred to {1}. Error: {2}." -f
          $source, $dest, $transferResult.failures[0].Message -Replace '(?:\s|\r|\n)',' ') #THIS IS THE PART WHERE THE ERROR.MESSAGE IS BLANK
        }  
      }
    
 
    }
    catch [WinSCP.SessionException] {
      Write-Host "Error: $($_.Exception.Message)"
      return 2
    }
    finally {
      # Terminate line after the last file (if any)
      if ($script:lastFileName -ne $Null) {
        Write-Host
      }  
      # Disconnect, clean up
      $session.Dispose()
    }
     

  }
  Catch {
      Write-Host ("Error: {0}" -f $_.Exception.Message)
  }
}

function Test-FTPFile{
  <#
      .SYNOPSIS
      Checks if a FTP File or Directory exists

      .DESCRIPTION
      Function returns True if a a FTP File or Directory exists in a given ftp site and folder

      .EXAMPLE
      Test-FTPFile -site 'ftp.avm.de' -remotefile '/fritzbox/fritzbox-7530/other/recover'
      Checks anonymously if the given remote ftp directory is available

      .EXAMPLE
      Get-FTPDirectory -site 'ftp.avm.de' -remotedir '/fritzbox/fritzbox-7530/other/recover/recover_de.txt'
      Checks anonymously if the given remote ftp file is available

      .NOTES
      
      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Get-Files

      .INPUTS
      -user            [<ftp username if ommited anonymous will be used>]
      -pass            [<ftp password if ommited anonymous will be used>]
      -site            <ftp server adress>
      -remotefile      <ftp remote resource>
      -secure          [<use FTP over SSL>]
      -port            [<Use specific FTP(s) Port>]
      -activemode      [<use ftp(s) ative mode>]
      -trustAnyTLSCert [<ignore any SSL trust errors only together with switch secure>]
      -enablelog       [<enable logging>]

      .OUTPUTS
      returns true or false
  #>   
  param
  (
    [Parameter(Mandatory = $false, 
    ValueFromPipelineByPropertyName = $true)]
    [string]
    $user="anonymous",
    [Parameter(Mandatory = $false, 
    ValueFromPipelineByPropertyName = $true)]
    [string]
    $pass="anonymous",
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Enter the ftp server like ftp.avm.de')]
    [string]
    $site,
    [int]
    $Port=0,
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Remote Directory or filepath to check like: /myftp/checkfile.txt or /myftp/mydirectory')]
    [string]
    $remotefile,
    [switch]
    $secure=$false,
    [switch]
    $activemode=$false,
    [switch]
    $trustAnyTLSCert=$false,
    [switch]
    $enablelog=$false
  )
  $script:lastFileName = $Null
  try {
     
        # Setup session options
        $sessionOptions = New-Object WinSCP.SessionOptions
        $sessionOptions.Protocol = [WinSCP.Protocol]::Ftp
        $sessionOptions.HostName = "$site"
        $sessionOptions.UserName = "$user"
        $sessionOptions.Password = "$pass"
        $sessionOptions.PortNumber = $Port
        if ($activemode) {
          $sessionOptions.FtpMode = [WinSCP.FtpMode]::Active
        }
    
        if ($secure) {
          $sessionOptions.FtpSecure = [WinSCP.FtpSecure]::Explicit
        }
    
        if($secure -and $trustAnyTLSCert) {
          $sessionOptions.GiveUpSecurityAndAcceptAnyTlsHostCertificate = $true
        } 
     
        $session = New-Object WinSCP.Session
        # Write log
        if ($enablelog) {
          $Session.SessionLogPath = "$env:TEMP\ftp.log" 
        }        
        try {
              
            # Connect
            $session.Open($sessionOptions)
     
            # Check files
            if ($session.FileExists($remoteFile)){
              write-host -foregroundcolor Green ("Exists: {0}" -f $remoteFile)
              #Now you can e.g. download file using session.GetFiles

              return $true
                 
            }
            else {
              write-host -foregroundcolor Yellow ("Not Exists: {0}" -f $remoteFile)
              return $false
            }            

        }
        catch [WinSCP.SessionException] {
          Write-Host "Error: $($_.Exception.Message)"
          return 2
        }
        finally {
 
          # Disconnect, clean up
          $session.Dispose()
        }
    }
  catch {
        Write-Host "Error: $($_.Exception.Message)"
        return 2
    }
}

function Show-FTPDirectory{
  <#
      .SYNOPSIS
      Lists the FTP File or Directory of a given ftp site

      .DESCRIPTION
      Lists the Files and/or Directories of a FTP site.
      You can define a remote ftp directory that should be enumerated. if ommitted the root '/' directory will be listed.

      .EXAMPLE
      Get-FTPDirectory -site 'ftp.avm.de'
      Lists the root ftp folder of site ftp.avm.de anonymously

      .EXAMPLE
      Get-FTPDirectory -site 'ftp.avm.de' -remotedir '/fritzbox/fritzbox-7530/other/recover'
      Lists the given ftp folder of site ftp.avm.de anonymously

      .NOTES
      
      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Get-Files

      .INPUTS
      -user            [<ftp username if ommited anonymous will be used>]
      -pass            [<ftp password if ommited anonymous will be used>]
      -site            <ftp server adress>
      -remotedir       <ftp remote directory>
      -secure          [<use FTP over SSL>]
      -port            [<Use specific FTP(s) Port>]
      -activemode      [<use ftp(s) ative mode>]
      -trustAnyTLSCert [<ignore any SSL trust errors only toghether with switch secure>]
      -enablelog       [<enable logging>]
      
      .OUTPUTS
      returns a Hash object of the folder/file structure
  #>  
  param
  (
    [Parameter(Mandatory = $false, 
    ValueFromPipelineByPropertyName = $true)]
    [string]
    $user="anonymous",
    [Parameter(Mandatory = $false, 
    ValueFromPipelineByPropertyName = $true)]
    [string]
    $pass="anonymous",
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Enter the ftp server like ftp.avm.de')]
    [string]
    $site,
    [int]
    $Port=0,
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]
    $remotedir="/",
    [switch]
    $secure=$false,
    [switch]
    $activemode=$false,
    [switch]
    $trustAnyTLSCert=$false,
    [switch]
    $enablelog=$false
  )
  try {
     
    $myObj = @()
    # Setup session options
       
    $sessionOptions = New-Object WinSCP.SessionOptions
    $sessionOptions.Protocol = [WinSCP.Protocol]::Ftp
    $sessionOptions.HostName = "$site"
    $sessionOptions.UserName = "$user"
    $sessionOptions.Password = $pass
    $sessionOptions.PortNumber = $Port
    
    if ($activemode) {
      $sessionOptions.FtpMode = [WinSCP.FtpMode]::Active
    }
    
    if ($secure) {
      $sessionOptions.FtpSecure = [WinSCP.FtpSecure]::Explicit
    }
    
    if($secure -and $trustAnyTLSCert) {
      $sessionOptions.GiveUpSecurityAndAcceptAnyTlsHostCertificate = $true
    }     
    $session = New-Object WinSCP.Session
    
    # Write log
    if ($enablelog) {
      $Session.SessionLogPath = "$env:TEMP\ftp.log" 
    }
        
        try {
              
            # Connect
            $session.Open($sessionOptions)
            
            # List files
            $directoryInfo = $session.ListDirectory($remotedir)
            # Print results
            foreach ($file in $directoryInfo.Files)
            { 
              if($file.isDirectory){
                
                $hash = [ordered]@{
                  Type             = $file.FileType
                  Permissions      = $file.FilePermissions.Text
                  Owner            = $file.Owner
                  Size             = $file.Length
                  LastWriteTime    = ($file.LastWriteTime).ToString("dd.MM.yyy HH:mm:ss")
                  Name             = $file.Name
                }
                $myObj += New-Object PSObject -Property $hash 
                #Write-Host  -foregroundcolor Yellow ("Directory: {0}" -f $file.Name)
              }
              elseif (!($file.isDirectory)) {
                $hash = [ordered]@{
                  Type             = "F"
                  Permissions      = $file.FilePermissions.Text
                  Owner            = $file.Owner
                  Size             = $file.Length                  
                  LastWriteTime    = ($file.LastWriteTime).ToString("dd.MM.yyyy HH:mm:ss")
                  Name             = $file.Name
                }
                $myObj += New-Object PSObject -Property $hash                 
                #Write-Host  -foregroundcolor green ("File: {0}" -f $file.Name)
              }
            }

        }
        catch [WinSCP.SessionException] {
          Write-Host "Error: $($_.Exception.Message)"
          return 2
        }
        finally
        {
          $myObj
          # Disconnect, clean up
          $session.Dispose()
        }
  }
  catch {
    Write-Host "Error: $($_.Exception.Message)"
    return 2
  }
}

function Sync-FTPDirectory{
  <#
      .SYNOPSIS
      Synchronize a local Directories and remote FTP Directories in all possible directions

      .DESCRIPTION
      Function synchonizes local or remote directories to Local to Remote or in Both directions

      .EXAMPLE
      Sync-FTPDirectory -site my.ftp.de -secure -Port 44572 -user 'JanTiede' -pass 'ftppassword' -localdir 'C:\temp\mytest\' -remotedir '/Dokumente/' -direction Both
      Synchronizes authenticated over FTPs on port 44572 all directories beginning at local source folder C:\temp\mytest\ and remote ftp directory /Dokumente/ in Both directions.

      .EXAMPLE
      Sync-FTPDirectory -site my.ftp.de -user 'JanTiede' -pass 'ftppassword' -localdir 'C:\temp\mytest\' -remotedir '/Dokumente/' -direction Remote
      Synchronizes authenticated over FTP on standard port 21 all directories beginning at local source folder C:\temp\mytest\ to the ftp remote folder /Dokumente/.

      .EXAMPLE
      Sync-FTPDirectory -site my.ftp.de -localdir 'C:\temp\mytest\' -remotedir '/Dokumente/' -direction Local -timeout 120
      Synchronizes anonymously over FTP on standard port 21 all directories from remote ftp directory /Dokumente/ to local source folder C:\temp\mytest\ with a ftp session timeout set to 120 seconds.

      .NOTES
      
      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Get-Files

      .INPUTS
      -user            [<ftp username if ommited anonymous will be used>]
      -pass            [<ftp password if ommited anonymous will be used>]
      -site            <ftp server adress>
      -localdir        <local directory>
      -remotedir       <remote directory>
      -direction       <choose target direction of Synchronization>
      -timeout         [<timeout in seconds>]
      -secure          [<use FTP over SSL>]
      -port            [<Use specific FTP(s) Port]
      -activemode      [<use ftp(s) ative mode>]
      -trustAnyTLSCert [<ignore any SSL trust errors only together with switch secure>]
      -enablelog       [<enable logging>]

      .OUTPUTS
      Synchronizes FTP Directories and outputs the Uploaded or Downloaded Files and Directories
  #>     
  param
  (
    [Parameter(Mandatory = $false, 
    ValueFromPipelineByPropertyName = $true)]
    [string]
    $user="anonymous",
    [Parameter(Mandatory = $false, 
    ValueFromPipelineByPropertyName = $true)]
    [string]
    $pass="anonymous",
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Enter the ftp server like ftp.avm.de')]
    [string]
    $site,
    [int]
    $Port=0,
    [SupportsWildcards()]
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Enter the local directory like c:\temp\somedir')]
    [string]
    $localdir,
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Enter the remote directory like /pub/somedir')]
    [string]
    $remotedir,
    [Parameter(Mandatory = $true, 
    ValueFromPipelineByPropertyName = $true, HelpMessage='Choose target direction of synchronization')]    
    [ValidateSet('Local', 'Remote', 'Both')]
    [string]
    $direction,
    [int]
    $timeout=30,
    [switch]
    $secure=$false,
    [switch]
    $activemode=$false,
    [switch]
    $trustAnyTLSCert=$false,
    [switch]
    $enablelog=$false
  )
  $script:lastFileName = $Null
  try {
     
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions
    $sessionOptions.Protocol = [WinSCP.Protocol]::Ftp
    $sessionOptions.HostName = "$site"
    $sessionOptions.UserName = "$user"
    $sessionOptions.Password = "$pass"
    $sessionOptions.PortNumber = $Port
    $sessionOptions.Timeout = New-TimeSpan -Seconds $timeout
            
    if ($activemode) {
          $sessionOptions.FtpMode = [WinSCP.FtpMode]::Active
    }
    
    if ($secure) {
          $sessionOptions.FtpSecure = [WinSCP.FtpSecure]::Explicit
    }
    
    if($secure -and $trustAnyTLSCert) {
          $sessionOptions.GiveUpSecurityAndAcceptAnyTlsHostCertificate = $true
    } 
     
    $session = New-Object WinSCP.Session
    # Write log
    if ($enablelog) {
      $Session.SessionLogPath = "$env:TEMP\ftp.log" 
    }     
           
        try{
          # Will continuously report progress of transfer
          $session.add_FileTransferProgress( { FileTransferProgress($_) } )
          
          # Connect
          $session.Open($sessionOptions)
     
          # Upload files
          $transferOptions = New-Object WinSCP.TransferOptions
          $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary     
          if ($direction -ne 'Both') {
            $synchronizationResult = $session.SynchronizeDirectories([WinSCP.SynchronizationMode]::$($direction), $localdir, $remotedir, $False, $true, [WinSCP.SynchronizationCriteria]::Time, $transferOptions)
          }
          else{
            $synchronizationResult = $session.SynchronizeDirectories([WinSCP.SynchronizationMode]::$($direction), $localdir, $remotedir, $False, $false, [WinSCP.SynchronizationCriteria]::Time, $transferOptions)
          }
          
          # Throw on any error
          $synchronizationResult.Check()
          
          if ($synchronizationResult.IsSuccess) {
            foreach ($download in $synchronizationResult.Downloads) {
              Write-Host -ForegroundColor Green ("Download file {0} to {1}" -f ($Download).FileName, ($Download).Destination)
            }
            foreach ($download in $synchronizationResult.Uploads) {
              Write-Host -ForegroundColor Green ("Upload   file {0} to {1}" -f ($Download).FileName, ($Download).Destination)
            }
          }
          elseif ($synchronizationResult.Failures -ne $null){
            foreach ($failure in $synchronizationResult.Failures) {
              Write-Host -ForegroundColor Red ("Error Sync file {0} to {1}" -f ($failure).FileName, ($failure).Destination)
            }     
          }
        }
        catch [WinSCP.SessionException]{
          Write-Host "Error: $($_.Exception.Message)"
          return 2
        }
        finally {
          # Terminate line after the last file (if any)
          if ($script:lastFileName -ne $Null)
          {
            Write-Host
          }
 
          # Disconnect, clean up
          $session.Dispose()
        }
     
        #exit 0
    }
  catch {
        Write-Host "Error: $($_.Exception.Message)"
        return 2
    }
}

function FileTransferProgress {
   param ($e)
   
   Write-Progress `
               -Id 0 -Activity "Loading" -CurrentOperation ("$($e.FileName) - {0:P0}" -f $e.FileProgress) -Status ("{0:P0} complete at $($e.CPS) bps" -f $e.OverallProgress) `
               -PercentComplete ($e.OverallProgress * 100)
}

# SIG # Begin signature block
# MIIXyAYJKoZIhvcNAQcCoIIXuTCCF7UCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfd8vrqmh68RCe5t31DxPbTa2
# 9d6gghL7MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggUqMIIEEqADAgECAhAN8Qu34dvmksZjfFpmTBzYMA0GCSqGSIb3DQEBCwUAMHIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJ
# RCBDb2RlIFNpZ25pbmcgQ0EwHhcNMTkwMjEyMDAwMDAwWhcNMjAwNjE2MTIwMDAw
# WjBnMQswCQYDVQQGEwJERTEQMA4GA1UECBMHQmF2YXJpYTEWMBQGA1UEBxMNVW50
# ZXJmb2VocmluZzEWMBQGA1UEChMNSmFuIFRpZWRlbWFubjEWMBQGA1UEAxMNSmFu
# IFRpZWRlbWFubjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMC0Chm9
# mwoGOWLPBF4UixkVEFCm8VJzfPPeVzcg4lls28aPuRHcP+5ZoZGo+skqnfL9TOrc
# dzafL3Ie+SLLvObBpzWyGUgF/sbW3YddnNCb0sXUEHcsH2ogtsbwBojFqhfaa4A9
# M8eIlC3a3jBT8fK6g/DELQ/XWiHXKHlkniJXvjaLa5NMA8/lPGUYCNfjQvkzeyg9
# 1D/9h7Vb/AlX1axRt3HJEsGZC0UuIzdNwNEU4QMk2X+U96fnM/EnR437nfFN59vd
# 4TKO5qYNL34Y0YMGw8Fxv8KUmv+4Ucfn+77jpTinbFS0+WsW43OT3n67j0bB3hNr
# /2OB8gT2Fg4DqDECAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrEuXsqCqOl6nED
# wGD5LfZldQ5YMB0GA1UdDgQWBBQ1ZwYXY4x5iFbme+4dWAblZgY2MDAOBgNVHQ8B
# Af8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1oDOgMYYv
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmww
# NaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3Mt
# ZzEuY3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEWHGh0
# dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEFBQcB
# AQR4MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBOBggr
# BgEFBQcwAoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hB
# MkFzc3VyZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZI
# hvcNAQELBQADggEBAC3LmroF0Px4BlTiSouFLtTsINZTIb2ZpzYoRFWRr8elJ4nn
# 3pPvvSH3SxkKiYOZZ+RBGQCBI2XHPgO45HnaXR5cjUcCMYl+vONpZubByxyPtuCy
# sBz717+7fb9nH4Kj1Yfk4RHr8M7l4yVPcsKaWnIXtgfLBi/TzH+0jSGQtMko2DlC
# h6Pm7qK+Ov2cWAg/MT3cqFE7ivVkRDcFS1ciSicFBQ1JJvl1k2FyDGLWlYlSt2/U
# uKOee4jQFZD2ulE2EffRlhDEu1JypMxRDX37ZS9JQmdJaRII6sIbUw1hNvP/xTwF
# wiWZJs0YJ7okcJOtZSG69Smdk35iAtC1k/Lah0QwggUwMIIEGKADAgECAhAECRgb
# X9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAi
# BgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEwMjIxMjAw
# MDBaFw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERp
# Z2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7RZmxOttE
# 9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p0WfTxvsp
# J8fTeyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj6YgsIJWu
# HEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grkV7tKtel0
# 5iv+bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHyDxL0xY4P
# waLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMBAAGjggHN
# MIIByTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUE
# DDAKBggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0f
# BHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNz
# dXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgGCmCGSAGG
# /WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQ
# UzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHwYD
# VR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQELBQADggEB
# AD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q3yBVN7Dh
# 9tGSdQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/kLEbBw6R
# Ffu6r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dcIFzZcbEM
# j7uo+MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6dGRrsutm
# Q9qzsIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT+hKUGIUu
# kpHqaGxEMrJmoecYpJpkUe8xggQ3MIIEMwIBATCBhjByMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5n
# IENBAhAN8Qu34dvmksZjfFpmTBzYMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRPOeEOSNuBpDbd
# MokKiqgjlc2hzDANBgkqhkiG9w0BAQEFAASCAQAVzD3UURVm3ycjbqn/eA2cMgLy
# S0Lwb8nauHsH3WAT6Ff8Kexow7F7NxQzAhL5ggV2cdMsVwU6ZPKv36nR7VVC/522
# wXekrCi7SdEkxskZNLSKzRsTXwYw8RACdnZ1XCNZCGLtrOi5PWtxjXsL3Ih8umU2
# WjLJRbStF40Ji7NUtjUCBPNAcWlFP0iEUz0mchXYa03c65AagJS8KRXiXWGCWGnY
# IkGdn/gM7qWOg8CrmrHN2BmEJH5mvLOo81/vQRTJNQ36y3OOd0pxfwftffBgNbKp
# C2V0TQWmyE2+RpHwrP58ItYJmk1UCEqd4f0uo9M8BNxv8jMcdydw7jZYqF00oYIC
# CzCCAgcGCSqGSIb3DQEJBjGCAfgwggH0AgEBMHIwXjELMAkGA1UEBhMCVVMxHTAb
# BgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQDEydTeW1hbnRlYyBU
# aW1lIFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzICEA7P9DjI/r81bgTYapgbGlAw
# CQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcN
# AQkFMQ8XDTE5MDYyNjA5MDY1MlowIwYJKoZIhvcNAQkEMRYEFA31tzFfu3QFTTPr
# WBKpApQYv9mEMA0GCSqGSIb3DQEBAQUABIIBACTVfew+/RiNTRCdb0QPwiutWfsF
# 4yit4Zdp3Lt7h312B4f7Wkp2M0T3HxTuB+3Wfez31kcORSpTYV8LkK0UzAp2XXuR
# zDQi6PPPIli2XrHtscRyEQxa/vZ+MajQMBDTzvokVsbl5lujAsEOVAqx8LznTMCq
# hCS89on8conaCaBiI90LzXp/klS3hsEONdaQUlZwiy65KJQqB2SdhwJPPoNuRG/f
# enrlniBSO8m5XoUfgp0i0lOeu+3FYBgRIMFC57fsERqp1DjuZASMwDs05wIRSImA
# cedmsxqwFaptxNiXAyYP6p0LY8DNpJU03T6TaBCtpQIL68GnlcppH10f/qc=
# SIG # End signature block
