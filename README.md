# WinSCP_FTP
WinSCP PowerShell automation module.

Contains basic FTP(s) Upload/Download/Sync/Test and Show FTP functions
-----------     ----                          -------    ------
Function        Get-FTP                       1.0        WinSCP_FTP
Function        Send-FTP                      1.0        WinSCP_FTP
Function        Show-FTPDirectory             1.0        WinSCP_FTP
Function        Sync-FTPDirectory             1.0        WinSCP_FTP
Function        Test-FTPFile                  1.0        WinSCP_FTP

----------------------------------------------------------------------------------------------------------------------------------------
NAME
    Send-FTP

SYNOPSIS
    Uploads a File or Directory to remote FTP Server


SYNTAX
    Send-FTP [[-user] <String>] [[-pass] <String>] [-site] <String> [[-Port] <Int32>] [-source] <String> [-dest] <String> [[-timeout] <Int32>] [-secure] [-activemode]
    [-trustAnyTLSCert] [-enablelog] [<CommonParameters>]


DESCRIPTION
    Function uploads file[s] and or directory[ies] to a ftp site and stores it to a given remote path


RELATED LINKS
    URLs to related sites
    The first link is opened by Get-Help -Online Get-Files

REMARKS
    To see the examples, type: "get-help Send-FTP -examples".
    For more information, type: "get-help Send-FTP -detailed".
    For technical information, type: "get-help Send-FTP -full".
    For online help, type: "get-help Send-FTP -online"
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


RELATED LINKS
    URLs to related sites
    The first link is opened by Get-Help -Online Get-Files

REMARKS
    To see the examples, type: "get-help Get-FTP -examples".
    For more information, type: "get-help Get-FTP -detailed".
    For technical information, type: "get-help Get-FTP -full".
    For online help, type: "get-help Get-FTP -online"
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


RELATED LINKS
    URLs to related sites
    The first link is opened by Get-Help -Online Get-Files

REMARKS
    To see the examples, type: "get-help Sync-FTPDirectory -examples".
    For more information, type: "get-help Sync-FTPDirectory -detailed".
    For technical information, type: "get-help Sync-FTPDirectory -full".
    For online help, type: "get-help Sync-FTPDirectory -online"
   
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


RELATED LINKS
    URLs to related sites
    The first link is opened by Get-Help -Online Get-Files

REMARKS
    To see the examples, type: "get-help Show-FTPDirectory -examples".
    For more information, type: "get-help Show-FTPDirectory -detailed".
    For technical information, type: "get-help Show-FTPDirectory -full".
    For online help, type: "get-help Show-FTPDirectory -online"
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


RELATED LINKS
    URLs to related sites
    The first link is opened by Get-Help -Online Get-Files

REMARKS
    To see the examples, type: "get-help Test-FTPFile -examples".
    For more information, type: "get-help Test-FTPFile -detailed".
    For technical information, type: "get-help Test-FTPFile -full".
    For online help, type: "get-help Test-FTPFile -online"
----------------------------------------------------------------------------------------------------------------------------------------
