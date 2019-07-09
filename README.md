# Stitchocker

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/alexaandrov/stitchocker/blob/master/LICENSE)
[![Release](https://img.shields.io/github/release/alexaandrov/stitchocker.svg?style=flat-square)](https://github.com/alexaandrov/stitchocker/releases/latest)
![GitHub file size in bytes](https://img.shields.io/github/size/alexaandrov/stitchocker/stitchocker.sh.svg)

**Stitchocker** its command line utility for stitching your docker-compose services.

# Installation

The easiest way to install the latest binaries for Linux and Mac is to run this in a shell:

**via curl**
```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/alexaandrov/stitchocker/master/install.sh)"
```

**via wget**
```bash
sudo bash -c "$(wget -O- https://raw.githubusercontent.com/alexaandrov/stitchocker/master/install.sh)"
```

### Manual installation

If you dont like to curl | bash you can download release from here:

https://github.com/alexaandrov/stitchocker/releases

Or via `git clone https://github.com/alexaandrov/stitchocker.git`

And then install script manually:

Option 1

```bash
sudo cp /path-to-release/stitchocker.sh /usr/local/bin/stitchocker
sudo chmod +x /usr/local/bin/stitchocker
```

Option 2

```bash
chmod +x /path-to-release/stitchocker.sh
```

In your .bashrc

```bash
alias stitchocker="/path-to-release/stitchocker.sh"
```

# Usage

First create in your services parent directory `docker-compose.yml' file.

This config file should be looks like:

```yaml
sets:
    # Default set running by default
    default:
        # You can refer to the services that are in the directory with the stithocker config (parent directory)

        parent-service-name
        
        # You can also point to relative sub directories
        
        folder-in-parent/another-folder/parent-service-name

        # You can refer to the exported paths in your shell config (eg ~/.bashrc).
        # In your shell config in this case should be:
        # export SERVICES="/absolute-path-to-services-dir"

        @services/service-name-in-services-alias
        
        # You can also specify the absolute path to the directory with the service docker compose config
        
        ~/you-services-dir/another-directory/service-name
        /home/user/you-services-dir/another-directory/service-name

        # You can import your custom sets

        @custom

    custom:
        another-parent-service-name
        @services/another-service-name-in-services-alias
```

Then run in your shell:

```bash
stitchocker up
```

Also you can run stitchocker in debug mode:

```bash
export STITCHOCKER_DEBUG=true
stitchocker up
```

Stitchocker help message
```bash
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

```bash
~ $ cat ~/.bashrc
export SERVICES="~/services"
```

```bash
~ $ cd ~/services
```

```bash
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

```bash
~ $ cd ~/projects/demo-project
```

```bash
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

```bash
~/projects/demo-project $ cat docker-compose.yml
```

```yaml
sets:
    default:
        - @services
        - platform
        - frontend-services/landing
        - @development

    services:
        - @services/reverse-proxy
        - /home/demo-user/services/mysql
        - ~/services/mysql
    
    development:
        - storybook
```

```bash
~/projects/demo-project $ stitchocker up
Starting reverse-proxy_proxy_1 ... done
Starting mysql_mysql_1 ... done
Starting redis_redis_1 ... done
Starting platform_platform_1 ... done
Starting landing_landing_1 ... done
Starting storybook_storybook_1 ... done
```

or

```bash
~/projects/demo-project $ stitchocker stop
Stoping reverse-proxy_proxy_1 ... done
Stoping mysql_mysql_1 ... done
Stoping redis_redis_1 ... done
Stoping platform_platform_1 ... done
Stoping landing_landing_1 ... done
Stoping storybook_storybook_1 ... done
```

or

```bash
~/projects/demo-project $ stitchocker up services
Starting reverse-proxy_proxy_1 ... done
Starting mysql_mysql_1 ... done
Starting redis_redis_1 ... done
```

or

```bash
~/projects/demo-project $ stitchocker up services devolpment
Starting reverse-proxy_proxy_1 ... done
Starting mysql_mysql_1 ... done
Starting redis_redis_1 ... done
Stoping storybook_storybook_1 ... done
```

And so on :)

# Copyright and license

Code released under the [Apache 2.0](https://raw.githubusercontent.com/alexaandrov/stitchocker/master/LICENSE) license. See LICENSE for the full license text.
