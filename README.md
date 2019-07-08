# Stitchocker

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/alexaandrov/stitchocker/blob/master/LICENSE)
[![Github All Releases](https://img.shields.io/github/downloads/alexaandrov/stitchocker/total.svg)]()
[![Release](https://img.shields.io/github/release/alexaandrov/stitchocker.svg?style=flat-square)](https://github.com/alexaandrov/stitchocker/releases/latest)
![GitHub file size in bytes](https://img.shields.io/github/size/alexaandrov/stitchocker/stitchocker.sh.svg)

**Stitchoker** its command line utility for stitching your docker-compose services.

# Installation

The easiest way to install the latest binaries for Linux and Mac is to run this in a shell:

```sh
curl -sSf https://raw.githubusercontent.com/alexaandrov/stitchocker/master/install.sh | sudo bash
```

### Manual installation

If you dont like to curl | bash you can download release from here:

https://github.com/alexaandrov/stitchocker/releases

Or via `git clone https://github.com/alexaandrov/stitchocker.git`

And then install script manually:

Option 1

```sh
sudo cp /path-to-release/stitchocker.sh /usr/local/bin/stitchocker
sudo chmod +x /usr/local/bin/stitchocker
```

Option 2

```
chmod +x /path-to-release/stitchocker.sh
```

In your .bashrc

```
alias stitchocker="/path-to-release/stitchocker.sh"
```

# Usage

Run in your shell

```
stitchocker -h
```

# Copyright and license

Code released under the [Apache 2.0](https://raw.githubusercontent.com/alexaandrov/stitchocker/master/LICENSE) license. See LICENSE for the full license text.