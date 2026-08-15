## Change Log:
- 1.9.3
Android 16 & Android 17 support
Verified compatibility with the refactored DeviceIdleController (JobScheduler APEX) and its dumpsys deviceidle whitelist interface
Improved XML matching for both single- and double-quoted package attributes
Extended conflicting-module cleanup to allow-in-power-save-except-idle
Fixed GMS removal not taking effect on Android 14+ by using the correct "dumpsys deviceidle sys-whitelist" command (the plain "whitelist" command only affects the user whitelist, so GMS stayed in the system power-save whitelist)
Removed a stray syntax error in the uninstall script
Fixed install-time merge when /product and /system/product point to the same files

- 1.9.2   
Android 15 support   
Improved root implementations (Support Magisk / KernelSU / APatch)   
Improved XML dir/path detections (73Sydney)   
Clear old GMS data on first install   

- 1.9.1   
Improved installation (Magisk Live and KernelSU)   
Fixed root method detections   
Fixed uninstaller script   

- 1.9.0   
Android 14 support      
Fixed synchronization for Location Sharing and Play Games   

- 1.8.8   
A long-awaited hotfix   
Addresses script that caused patching XML gone wrong   
Raised Magisk Boot Service to 100 seconds   

- 1.8.7   
Android 13 support   
Added GMS to battery optimization and disabled another components   
Fixed broken API checking and Multi-User support   
Moved to inbuilt (Magisk) BusyBox   
Improved pre-boot conflict fixer and proper boot script execution   
Improved superuser checking method and used cmd flag arguments   
Improved XML patching logic   
Minimized root path checking depth   
Revived overall code quality and syntax   
Rewrite GMS state checker bin   

- 1.8.6   
Added /system_ext detection support   
Improved patching detections (Allow to revoke location permissions)   

- 1.8.5   
Added updateJson support   
Improved patching detections (XML files)   

- 1.8.4   
Removed redundant script (GMS: Stay with disabling Find My Device only)   

- 1.8.3   
Android 12 support   
Additional boot complete check   
Multi-User support   
Set ignore for GMS and IMS WRITE_SETTINGS   
Minor improvements   

- 1.8.2   
Android 11 support   
Improved installation (Magisk Live and Custom Recovery)   
Improved patching detections (XML files and conflicting modules)   
Integrated add-on (run 'gmsc' with superuser rights for check optimization status)   
Set ignore for GMS and IMS BOOT_COMPLETED   
Set ignore for GMS and IMS AUTO_START (custom permissions for Oxygen OS)   
Updated template   

- 1.8.1   
Integrated custom recovery installation   
Added boot logic for search and patch any conflicting modules (if present)   
Whitelisted IMS and Turbo (this should fixed location crash issue in MIUI)   

- 1.8.0   
Initial re-release   
100 seconds Magisk Boot Service   
