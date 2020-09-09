# README #

I am an independent developer and am in no way associated or affiliated with 3CX Ltd. This software comes with no warranty and no guarantee of any kind. That being said, I work very hard to ensure this program continues to work and until 3CX has a solution for syncing Extensions and Groups this will be maintained.

### NOTICE ###
This application is not compatible with older versions of 3CX. It support specifically version 16.0.641. Updates to 3CX may break functionality.
Version 2.0.1 = 3CX Version 16+ But less than 16.0.641
Version 3.0.0 = 3CX Version 16.0.641

### What is this repository for? ###

* Powershell program that can synchronize extensions in any 3CX installation. It can also populate groups and create hotdesking accounts if provided.

### Requirements ###
* Powershell >= 5.1 (Tested in Ubuntu and Windows Server 2016)
* CSV Data
* Administrator account to a 3CX installation running version 16.0.641+

### How do I get set up? ###
* Checkout the latest master branch
* Run the setup.ps1 script to generate the initial config
* A JSON mapping file named Mapping.json must be created to match CSV headers to API field paths in 3CX. See below for more details.

### Usage ###

After running Setup to configure the program you can run 3cx Sync.ps1 with the following flags. Running with no flags executes the program from start to finish.

| Function name | Description                    |
| ------------- | ------------------------------ |
| `WhatIf`      | Performs a WhatIf to show what would happen in 3CX. No changes will be made   |
| `NoExtensions`   | Skip syncing extensions     |
| `NoNewExtensions` | Skip creating extensions. Ignored if NoExtensions is already set. |
| `NoUpdateExtensions` | Skip updating extensions. Ignored if NoExtensions is already set. |
| `NoGroupMemberships` | Skip syncing group memberships |
| `NoHotdesking` | Do not create hotdesks (Should be set once hotdesks are created) |

### Mapping Configuration ###
Make a copy of the Mapping.json.example file. Here I'll explain the basic structure as it exists in the latest version.

* Extensions 
	* Path: Must contain a path to a csv file containing data used to compare against existing extensions
	* Number: Required to specify which CSV header is the Number of the extension. Format is "Number":"CSVNumberHeader"
	* New: Used to map the 3CX value to the CSV header. Note that not all 3CX values are supported yet. Format is "3CXValue": "CSVHeader"
	* Update: Used to map the 3CX value just like New. Only list mappings here you wish to update after creation
* GroupMembership:
	* Path: Must contain a path to a csv file containing data used to determine group membership.
	* Groups: Formatted like "Group Name in 3CX": {"Conditions":[]}. Note you must create the groups by hand initially for this to sync them. Groups not listed will not be touched.
		* Conditions: array of objects like {"Field": "CSVHeaderField", "Value":"Value to match"}. You may list multiple Conditions and it will use an AND operator by default.
		Conditions do not support OR operators yet. An empty array will include all extensions.

### Contribution guidelines ###

* Feel free to create a fork, write changes, and pull request

### Who do I talk to? ###

* If you have questions feel free to file an Issue or contact the repo owner

### Releases ###
##### 3.0.0 - Major Upgrade #####
* Overhaul of Group Memberships
	* Much faster at comparing group memberships so long as a group doesn't require ALL extensions to be added
	* Works with 3CXs updated API for pulling group membership and possible memberships
	* Works with 3CXs updated API for type casting of values
	* Simplified mapping file slightly (Will need to be changed; Check Sample)
##### 2.0.1 - Minor Upgrade #####
* Updated Readme to include releases
* Updated example mapping and readme information for how to get started
##### 2.0.0 - Major Upgrade #####
##### 1.0.0 - Beta Initial Release #####