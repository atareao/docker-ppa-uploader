
# Uploading sources to Launchpad PPA in Docker Container

## Overview

Docker can be used to set up a clean build environment for Debian
packaging.  This tutorial shows how to create a container with
required build tools and how to use it to upload packages to PPA.

This is an original idea and initial code of Tero Saarni, as you can see in
the LICENSE

## Create build environment

Start by building a container that will act as package build environment:

```bash
docker build -t docker-ppa-uploader:22.04 -f Dockerfile-ubuntu-22.04 .
```

In this example the target is Ubuntu 22.04 but you can create and
modify `Dockerfile-nnn` to match your target environment.

## Building packages

First download or git clone the source code of the package you are
building:

```bash
git clone ... ~/my-package-source
```


The source code should contain subdirectory called `debian` with at
least a minimum set of packaging files: `control`, `copyright`,
`changelog` and `rules`.

Clone the
[docker-deb-builder](https://github.com/atareao/docker-ppa-uploader)
(the repository you are reading now) and run the build script to see
usage:

```bash
$ ./upload
usage: upload [options...] SOURCEDIR
Options:
  -i IMAGE  Name of the docker image (including tag) to use as package build and upload environment.
  -d DIR    Directory that contains other deb packages that need to be installed before build.
```

To upload packages run following commands:

    # build package from source directory
```bash
./build -i docker-ppa-uploader:22.04 ~/my-package-source
```

Sometimes build might require dependencies that cannot be installed with
`apt-get build-dep`.  You can install them into the build environment
by passing option `-d DIR` where DIR is a directory with `*.deb` files
in it.

```bash
./build -i docker-ppa-uploader:22.04 -d dependencies ~/my-package-source
```

## Change  version

In order to change version you can do,

```bash
./dch -i docker-ppa-uploader:22.04 ~/my-package-source
```
