# DESCRIPTION

The M6::App::Config class aims at centralising configuration values using a hierarchical set of YAML files, thereby closely resembling Hiera.

This module is used by AMS-IX's platform software (provisioning, monitoring, etc.).

The module works with a global configuration file (/etc/m6-app-config/m6-app-config.yml) that specifies the hierarchy of files to read for configuration information.

Variable interpolation in values is supported through YAML::AppConfig(3).

# SEE ALSO

Hiera https://docs.puppet.com/hiera/

# TASKS

The folder structure of the configuration files is as follows:
- parent_directory
- One DEFAULT folder
- Several .yaml files inside default folder
- One folder per amsix exchange (one for Netherlands, one for NewYork, etc)
- Several .yaml files inside each folder
        
When the same variable is defined in DEFAULT folder, and in one of the site specific folders (for example NL), the most specific variable (NL) must prevale, overriding the DEFAULT one.
Your task here is to complete the following:
- Refactor this module to make it more OO (using Moo). 
  Create a new branch, and once you're ready, create a merge request, so we can review and merge your changes.
  
- For extra credit, you're welcome to write unit tests, to cover the new code added.

- The module has some fundamental issues. The hierarchy is not working as it is described, even though it may seem so. 
  Can you describe what is the issue, and offer a fix? (You don't have to implement it)
  
- Create a debian package out of it (notice the debian directory is already created) 
  and include it in your merge request in an extra directory called 'pkg'.

If you have any questions / concerns, let us please know!

Good luck!
