# WinSCP_FTP PowerShell automation module.

Contains basic FTP(s) Upload/Download/Sync/Test and Show FTP functions
----------- -----------------------------------------------------------
Type        |    Name                  |     Version  |    Module      |
------------|--------------------------|--------------|----------------|
Function    |    Get-FTP               |        1.0   |     WinSCP_FTP |
Function    |    Send-FTP              |        1.0   |     WinSCP_FTP |
Function    |    Show-FTPDirectory     |        1.0   |     WinSCP_FTP |
Function    |    Sync-FTPDirectory     |        1.0   |     WinSCP_FTP |
Function    |    Test-FTPFile          |        1.0   |     WinSCP_FTP |

----------------------------------------------------------------------------------------------------------------------------------------
Screenshot<img src="https://github.com/BetaHydri/WinSCP_FTP/blob/master/sample transfer.png"/>
----------------------------------------------------------------------------------------------------------------------------------------
## Functions

NAME
    
    Send-FTP

SYNOPSIS
    
    Uploads a File or Directory to remote FTP Server


SYNTAX
    
    Send-FTP [[-user] <String>] [[-pass] <String>] [-site] <String> [[-Port] <Int32>] [-source] <String> [-dest] <String> [[-timeout] <Int32>] [-secure] [-activemode]
    [-trustAnyTLSCert] [-enablelog] [<CommonParameters>]


DESCRIPTION
    
    Function uploads file[s] and or directory[ies] to a ftp site and stores it to a given remote path

----------------------------------------------------------------------------------------------------------------------------------------

NAME
    
    Get-FTP

SYNOPSIS
    
    Downloads a File or Directory to remote FTP Server


SYNTAX
    
    Get-FTP [[-user] <String>] [[-pass] <String>] [-site] <String> [[-Port] <Int32>] [-source] <String> [-dest] <String> [[-timeout] <Int32>] [-secure] [-activemode]
    [-trustAnyTLSCert] [-enablelog] [<CommonParameters>]


DESCRIPTION
    
    Function downloads file[s] and or directory[ies] to a ftp site and stores it to a given remote path

----------------------------------------------------------------------------------------------------------------------------------------

NAME
    
    Sync-FTPDirectory

SYNOPSIS
    
    Synchronize a local Directories and remote FTP Directories in all possible directions


SYNTAX
    
    Sync-FTPDirectory [[-user] <String>] [[-pass] <String>] [-site] <String> [[-Port] <Int32>] [-localdir] <String> [-remotedir] <String> [-direction] <String> [[-timeout] <Int32>]
    [-secure] [-activemode] [-trustAnyTLSCert] [-enablelog] [<CommonParameters>]


DESCRIPTION
    
    Function synchonizes local or remote directories to Local to Remote or in Both directions

----------------------------------------------------------------------------------------------------------------------------------------

NAME
    
    Show-FTPDirectory

SYNOPSIS
    
    Lists the FTP File or Directory of a given ftp site


SYNTAX
    
    Show-FTPDirectory [[-user] <String>] [[-pass] <String>] [-site] <String> [[-Port] <Int32>] [[-remotedir] <String>] [-secure] [-activemode] [-trustAnyTLSCert] [-enablelog]
    [<CommonParameters>]


DESCRIPTION
    
    Lists the Files and/or Directories of a FTP site.
    You can define a remote ftp directory that should be enumerated. if ommitted the root '/' directory will be listed.

----------------------------------------------------------------------------------------------------------------------------------------

NAME
    
    Test-FTPFile

SYNOPSIS
    
    Checks if a FTP File or Directory exists


SYNTAX
    
    Test-FTPFile [[-user] <String>] [[-pass] <String>] [-site] <String> [[-Port] <Int32>] [-remotefile] <String> [-secure] [-activemode] [-trustAnyTLSCert] [-enablelog]
    [<CommonParameters>]


DESCRIPTION
    
    Function returns True if a a FTP File or Directory exists in a given ftp site and folder

----------------------------------------------------------------------------------------------------------------------------------------
