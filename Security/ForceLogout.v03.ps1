<## ----- About: ----
    # Backup.Management Force Logout
    # Revision v03 - 2021-08-23
    # Author: Eric Harless, Head Backup Nerd - SolarWinds 
    # Twitter @Backup_Nerd  Email:eric.harless@solarwinds.com
# -----------------------------------------------------------#>  ## About

<# ----- Legal: ----
    # Sample scripts are not supported under any SolarWinds support program or service.
    # The sample scripts are provided AS IS without warranty of any kind.
    # SolarWinds expressly disclaims all implied warranties including, warranties
    # of merchantability or of fitness for a particular purpose. 
    # In no event shall SolarWinds or any other party be liable for damages arising
    # out of the use of or inability to use the sample scripts.
# -----------------------------------------------------------#>  ## Legal

<# ----- Compatibility: ----
    # For use with the Standalone edition of SolarWinds Backup
# -----------------------------------------------------------#>  ## Compatibility

<# ----- Behavior: ----
    # Wait for Idle
    # Query running browsers
    # Send logout URL to running browsers
    # Close logout URL browser tabs
    # 
    # start with
    # 	powershell.exe -windowstyle hidden -executionpolicy Unrestricted -file "P:\ATH\TO\Forcelogout.v##.ps1"
    #   
# -----------------------------------------------------------#>  ## Behavior
    
#region ----- Environment, Variables, Names and Paths ----    
    Clear-Host
    $Script:Browsers = @("FireFox","Chrome","MSEdge")
    $Script:PrivateBrowsers = @{
        Firefox = "-private-window"
        Chrome = "-incognito"
        MSEdge = "-inprivate"
     }

    $Script:BackupLogoutURL = "https://sso.navigatorlogin.com/connect/endsession?post_logout_redirect_uri=https%3A%2F%2Fbackup.management%2Flogout"
    #$Script:BackupLogoutURL = "https://sso.navigatorlogin.com/connect/endsession?post_logout_redirect_uri=https%3A%2F%2Fsso.navigatorlogin.com"

    # $Script:RMMLogoutURL = "https://dashboard.systemmonitor.us/dashboard/default.php?logout=true"
    # $Script:TCLogoutURL ="https://admin.swi-tc.com/admin_area_/sso_action.php?action=logout"
    $idle_timeout = New-TimeSpan -minutes 15
    
    $scriptpath = $MyInvocation.MyCommand.Path
    $dir = Split-Path $scriptpath
    Push-Location $dir
#endregion ----- Environment, Variables, Names and Paths ----

    Function ForceLogout {
        
        foreach($Process in $Script:Browsers) {
            $string = $PrivateBrowsers.$process
            $isRunning = Get-Process $Process -ea SilentlyContinue
                if(($isRunning) -ne $null) {

                    Start-Process $process -ArgumentList "$Script:BackupLogoutURL"
                    Write-Output "  $process | standard browser logged out of Backup.Management" 
                    Start-Sleep 7
                    $wshell = New-Object -ComObject wscript.shell
                    $wshell.SendKeys("^w")                          ## CTRL-W Closes browser tab used to opened logout URL
                    Start-Sleep 10

                    Start-Process $process -ArgumentList "$string $Script:BackupLogoutURL"
                    Write-Output "  $process | $string browser logged out of Backup.Management" 
                    Start-Sleep 7
                    $wshell = New-Object -ComObject wscript.shell
                    $wshell.SendKeys("^w")                          ## CTRL-W Closes browser tab used to opened logout URL
                    Start-Sleep 10
                


                }elseif(($isRunning) -eq $null) {

                    Start-Process $process -ArgumentList "$Script:BackupLogoutURL"
                    Write-Output "  $process | Clearing Backup.Management from inactive browser" 
                    Start-Sleep 10
                    $wshell = New-Object -ComObject wscript.shell
                    $wshell.SendKeys("^w")                          ## CTRL-W Closes browser tab used to opened logout URL
                    Start-Sleep 10

                }



        }
    }

# This snippet is from http://stackoverflow.com/a/15846912
Add-Type @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
namespace PInvoke.Win32 {
    public static class UserInput {
        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }
        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }
        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }
        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@
#End snippet

# Helper: Is currently locked?
    $logout = 0;

    do {
        # 1st: How long is your computer currently idle?
        $idle_time = [PInvoke.Win32.UserInput]::IdleTime;
        Write-Host ("  Signout Backup.Management if idle for $idle_timeout minutes`n  Current idle time " + $idle_time);

        # Your computer idle time is longer than allowed, so Logout
        if (($logout -eq 0) -And ($idle_time -gt $idle_timeout)) {
            # Logout

            ForceLogout

            # Setting $logout to 1 will prevent it from logging out every 15 seconds
            $logout = 1;
            #Write-Host ("Locking");
        }

        # Your idle time is less than the allowed time, resetting logout flag

        if ($idle_time -lt $idle_timeout) {
            $logout = 0;
        }

        # Save the environment. Don't use 100% of a single CPU just for idle checking :)
        Start-Sleep -Seconds 3
        Clear-Host
        
    }
    while (1 -eq 1)



