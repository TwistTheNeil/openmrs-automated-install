## Automate OpenMRS installation
This repository will contain a script/collection of scripts which will help
automate the installation of OpenMRS on select operating systems.

_As of now, I will be supporting debian and debian based distributions._

### Usage (as root for linux):
_./linux-install.sh_

### Info:
This script installs all the dependencies required to run an instance of
OpenMRS standalone on Debian, Ubuntu, Debian derived distributions, and
Fedora. After attempting to deploy OpenMRS, it will present a firefox
instance loaded with a url which points to OpenMRS which the user will
have to manually configure according to their liking.

### Note:
This is **not** a setup for the development environment, just the standalone
instance.
It takes Tomcat anywhere between 2-10 minutes to notice that openMRS
has been deployed.

### Demonstration:
[Youtube](https://www.youtube.com/watch?v=o-78lKiN0eE)
