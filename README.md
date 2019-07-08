# Stitchocker

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/alexaandrov/stitchocker/blob/master/LICENSE)
[![Release](https://img.shields.io/github/release/alexaandrov/stitchocker.svg?style=flat-square)](https://github.com/alexaandrov/stitchocker/releases/latest)
![GitHub file size in bytes](https://img.shields.io/github/size/alexaandrov/stitchocker/stitchocker.sh.svg)

**Stitchocker** its command line utility for stitching your docker-compose services.

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

First create in your services parent directory `docker-compose.yml' file.

This config file should be looks like:

```
sets:
    # Default set running by default
    default:
        # You can refer to the services that are in the directory with the stithocker config (parent directory)

        parent-service-name

        # You can refer to the exported paths in your shell config (eg ~/.bashrc).
        # In your shell config in this case should be:
        # export SERVICES="/absolute-path-to-services-dir"

        services/service-name-in-services-alias

        # You can import your custom sets

        @custom
    custom:
        another-parent-service-name
        services/another-service-name-in-services-alias
```

Then run in your shell:

```
stitchocker up
```

Also you can run stitchocker in debug mode:

```
export STITCHOCKER_DEBUG=true
stitchocker up
```

Stitchocker help message
```
$ stitchocker -h

Usage:
        stitchocker [-a <arg>...] [alias] [docker-compose COMMAND] [SETS...]
        stitchocker [docker-compose COMMAND] [SETS...]
        stitchocker -h|--help

Options:
        -h  Shows this help text
        -p  Path to stitching directory
        -a  Alias to stitching directory

Examples:
        stitchocker up
        stitchocker up default backend frontend
        stitchocker -a my-projects-alias-from-env up default backend frontend
```

# Usage Example

```
~ $ cat ~/.bashrc
export SERVICES="~/services"
```

```
~ $ cd ~/services
```

```
~/services $ tree .
├── reverse-proxy
    └── ...
    └── docker-compose.yml
├── mysql
    └── ...
    └── docker-compose.yml
├── redis
    └── ...
    └── docker-compose.yml
```

```
~ $ cd ~/projects/demo-project
```

```
~/projects/demo-project $ tree .
├── docker-compose.yml
├── platform
    └── ...
    └── docker-compose.yml
├── landing
    └── ...
    └── docker-compose.yml
├── storybook
    └── ...
    └── docker-compose.yml
```

```
~/projects/demo-project $ cat docker-compose.yml
sets:
    default:
        - @services
        - platform
        - landing
        - @development

    services:
        - services/reverse-proxy
        - services/mysql
        - services/redis
    
    development:
        - storybook
```

```
~/projects/demo-project $ stitchocker up
Starting reverse-proxy_proxy_1 ... done
Starting mysql_mysql_1 ... done
Starting redis_redis_1 ... done
Starting platform_platform_1 ... done
Starting landing_landing_1 ... done
Starting storybook_storybook_1 ... done
```

or

```
~/projects/demo-project $ stitchocker stop
Stoping reverse-proxy_proxy_1 ... done
Stoping mysql_mysql_1 ... done
Stoping redis_redis_1 ... done
Stoping platform_platform_1 ... done
Stoping landing_landing_1 ... done
Stoping storybook_storybook_1 ... done
```

or

```
~/projects/demo-project $ stitchocker up services
Starting reverse-proxy_proxy_1 ... done
Starting mysql_mysql_1 ... done
Starting redis_redis_1 ... done
```

or

```
~/projects/demo-project $ stitchocker up services devolpment
Starting reverse-proxy_proxy_1 ... done
Starting mysql_mysql_1 ... done
Starting redis_redis_1 ... done
Stoping storybook_storybook_1 ... done
```

And so on :)

# Copyright and license

Code released under the [Apache 2.0](https://raw.githubusercontent.com/alexaandrov/stitchocker/master/LICENSE) license. See LICENSE for the full license text.