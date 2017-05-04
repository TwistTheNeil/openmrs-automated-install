## Automate OpenMRS installation
This repository will contain a script/collection of scripts which will help
automate the installation of OpenMRS on select operating systems.

_As of now, I will be supporting debian and ubuntu._
_Unfortunately, I can't support many systems with varying configurations._

### Usage (as root for linux):
_./linux-install.sh_

### Info:
This script installs all the dependencies required to run an instance of
OpenMRS standalone.

Current list of systems supported:
* Debian (stable)
* Ubuntu (LTS)
* CentOS 7 (Unofficially by [besmirzanaj](https://github.com/besmirzanaj))
* Fedora (Unofficially by [devinmcginty](https://github.com/devinmcginty))
* Mac (Unofficially by [TheBenderman](https://github.com/TheBenderman))

After attempting to deploy OpenMRS, it will present a firefox
instance loaded with a url which points to OpenMRS which the user will
have to manually configure according to their liking.

### Note:
This is **not** a setup for the development environment, just the standalone
instance.
It takes Tomcat anywhere between 2-10 minutes to notice that openMRS
has been deployed.

### Demonstration:
[Youtube](https://www.youtube.com/watch?v=o-78lKiN0eE)

### Contributers:
[Click here for awesome people profiles :)](https://github.com/TwistTheNeil/openmrs-automated-install/graphs/contributors)
