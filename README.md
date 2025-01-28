# mac_manipulator
Enables manual changes to hardware addresses on network adapters (Windows 10/11)

### Licensing
All code in this repository will be licensed under the BSD 3-Clause License.

### Usage
The script is interactive by default, though there are optional parameters being implemented.

So far a few have been added:

*-Interface [int]*
  - Select a network adapter for the script to work on (to see its value in the menu, run the script.) Takes a single argument.
  - Example: `mac_manipulator.ps1 -Interface 3`
    
*-Random [y]*
  - Select the first randomized hardware address generated, rather than prompting.
  - Example: `mac_manipulator.ps1 -Random y`
