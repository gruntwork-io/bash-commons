[![Maintained by Gruntwork.io](https://img.shields.io/badge/maintained%20by-gruntwork.io-%235849a6.svg)](https://gruntwork.io/?ref=repo_bash_commons)
# Bash Commons

This repo contains a collection of reusable Bash functions for handling common tasks such as logging, assertions,
string manipulation, and more. It is our attempt to bring a little more sanity, predictability, and coding reuse to our
Bash scripts. All the code has thorough automated tests and is packaged into functions, so you can safely import it
into your bash scripts using `source`.




## Examples

Once you have `bash-commons` installed (see the [install instructions](#install)), you use `source` to import the
modules and start calling the functions within them. Before you import any modules, make sure you `source` the
`bootstrap.sh` file which sets some important defaults to encourage good code:

```bash
source /opt/gruntwork/bash-commons/bootstrap.sh
source /opt/gruntwork/bash-commons/log.sh
source /opt/gruntwork/bash-commons/assert.sh
source /opt/gruntwork/bash-commons/os.sh

log_info "Hello, World!"

assert_not_empty "--foo" "$foo" "You must provide a value for the --foo parameter."

if os_is_ubuntu "16.04"; then
  log_info "This script is running on Ubuntu 16.04!"
elif os_is_centos; then
  log_info "This script is running on CentOS!"
fi
```

## Install

The first step is to download the code onto your computer.

The easiest way to do this is with the [Gruntwork Installer](https://github.com/gruntwork-io/gruntwork-installer)
(note, you'll need to replace `<VERSION>` below with a version number from the [releases
page](https://github.com/gruntwork-io/bash-commons/releases)):

```bash
gruntwork-install \
  --repo https://github.com/gruntwork-io/bash-commons \
  --module-name bash-commons \
  --tag <VERSION>
```

The default install location is `/opt/gruntwork/bash-commons`, but you can override that using the `dir` param, and
override the owner of the install dir using the `owner` and `group` params:

```bash
gruntwork-install \
  --repo https://github.com/gruntwork-io/bash-commons \
  --module-name bash-commons \
  --tag <VERSION> \
  --module-param dir=/foo/bar \
  --module-param owner=my-os-username \
  --module-param group=my-os-group
```

If you don't want to use the Gruntwork Installer, you can use `git clone` to get the code onto your computer and then
copy it to it's final destination manually:

```bash
git clone --branch <VERSION> https://github.com/gruntwork-io/bash-commons.git

sudo mkdir -p /opt/gruntwork
cp -r bash-commons/modules/bash-commons/src /opt/gruntwork/bash-commons
sudo chown -R "my-os-username:my-os-group" /opt/gruntwork/bash-commons
```

## Instance Metadata Service versions

`bash-commons` supports both Instance Metadata Service (IMDS) version 1 and 2. Gruntwork and AWS both recommend using version 2 of the Instance Metadata Service whenever possible. Although version 1 is still supported and considered fully secure by AWS, version 2 has been specially hardened against specific threat vectors and is therefore preferable.  Version 2 is now the default since all new instances support it by default.

To understand more about Instance Metadata Service version 2 and its features, read [the official AWS documentation on IMDSv2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html).

If you need help detecting what is still using IMDSv1 AWS has a PacketAnalyzer:
https://github.com/aws/aws-imds-packet-analyzer

There are two ways to specify the version of the Instance Metadata Service that `bash-commons` should use:

1. Set the environment variable `GRUNTWORK_BASH_COMMONS_IMDS_VERSION` to the version of IMDS that you wish to use. Valid values are either `1` or `2`.
2. Change the value of `default_instance_metadata_version` to either `1` or `2`.

#### Example of `dynamic-ubuntu-wait.sh` usage:

You can use the `dynamic-ubuntu-wait.sh` command after you [install bash-commons](#install):

```
bash /opt/gruntwork/bash-commons/dynamic-ubuntu-wait.sh
```

Alternatively, you can call the script without installing by curling it during your existing provisioning/automated installation process:

```bash
curl -LsS https://raw.githubusercontent.com/gruntwork-io/bash-commons/[VERSION]/modules/bash-commons/src/dynamic-ubuntu-wait.sh | bash`
```

Where `[VERSION]` could be: `v0.0.3`. The latest release can be found [here](https://github.com/gruntwork-io/bash-commons/releases/latest)




## Importing modules

You can use the `source` command to "import" the modules you need and use them in your code:

```bash
source /opt/gruntwork/bash-commons/log.sh
```

This will make all the functions within that module available in your code:

```bash
log_info "Hello, World!"
```




## Available modules

Here's an overview of the modules available in `bash-commons`:

* `array.sh`: Helpers for working with Bash arrays, such as checking if an array contains an element, or joining an
  array into a string with a delimiter between elements.

* `assert.sh`: Assertions that check a condition and exit if the condition is not met, such as asserting a variable is
  not empty or that an expected app is installed. Useful for defensive programming.

* `aws.sh`: A collection of thin wrappers for direct calls to the [AWS CLI](https://aws.amazon.com/cli/) and [EC2
  Instance Metadata](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html). These thin
  wrappers give you a shorthand way to fetch certain information (e.g., information about an EC2 Instance, such as its
  private IP, public IP, Instance ID, and region). Moreover, you can swap out `aws.sh` with a version that returns mock
  data to make it easy to run your code locally (e.g., in Docker) and to run unit tests. This requires IMDS to be enabled.

* `aws-wrapper.sh`: A collection of "high level" wrappers for the [AWS CLI](https://aws.amazon.com/cli/) and [EC2
  Instance Metadata](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) to simplify common
  tasks such as looking up tags or IPs for EC2 Instances. Note that these wrappers handle all the data processing and
  logic, whereas all the direct calls to the AWS CLI and EC2 metadata endpoints are delegated to `aws.sh` to make unit
  testing easier.

* `dynamic-ubuntu-wait.sh`: A script that dynamically waits for Ubuntu automatic update mechanism to
 release all locks so that `apt-get` may run without errors.

* `file.sh`: A collection of helpers for working with files, such as checking if a file exists or contains certain text.

* `log.sh`: A collection of logging helpers that write logs to `stderr` with log levels (INFO, WARN, ERROR) and
  timestamps.

* `os.sh`: A collection of Operating System helpers, such as checking which flavor of Linux (e.g., Ubuntu, CentOS) is
  running and validating checksums.

* `string.sh`: A collection of string manipulation functions, such as checking if a string contains specific text,
  stripping prefixes, and stripping suffixes.
  


## Coding principles

The code in `bash-commons` follows the following principles:

1. [Compatibility](#compatibility)
1. [Code style](#code-style)
1. [Everything is a function](#everything-is-a-function)
1. [Namespacing](#namespacing)
1. [Testing](#testing)


### Compatibility

The code in this repo aims to be compatible with:

* Bash 3
* Most major Linux distributions (e.g., Ubuntu, CentOS)


### Code style

All the code should mainly follow the [Google Shell Style Guide](https://google.github.io/styleguide/shell.xml).
In particular:

* The first line of every script should be `#!/usr/bin/env bash`.
* All code should be defined in functions.
* Functions should exit or return 0 on success and non-zero on error.
* Functions should return output by writing it to `stdout`.
* Functions should log to `stderr`.
* All variables should be `local`. No global variables are allowed at all.
* Make as many variables `readonly` as possible.
* If a variable is both local and readonly, use `local -r`. 
* If calling to a subshell and storing the output in a variable (foo=`$( ... )`), do NOT use `local -r`  in the same
  statement or the [exit code will be lost](https://blog.gruntwork.io/yak-shaving-series-1-all-i-need-is-a-little-bit-of-disk-space-6e5ef1644f67).
  Instead, declare the variable as `local` on one line and then call the subshell on the next line.
* Quote all strings.
* Use `[[ ... ]]` instead of `[ ... ]`.
* Use snake_case for function and variable names. Use UPPER_SNAKE_CASE for constants.


### Everything in a function

It's essential that ALL code is defined in a function. That allows you to use `source` to "import" that code without
anything actually being executed.


### Namespacing

Bash does not support namespacing, so we fake it using a convention on the function names: if you create a file
`<foo.sh>`, all functions in it should start with `foo_`. For example, all the functions in `log.sh` start with `log_`
(`log_info`, `log_error`) and all the functions in `string.sh` start with `string_` (`string_contains`,
`string_strip_prefix`). That makes it easier to tell which functions came from which modules.

For readability, that means you should typically give files a name that is a singular noun. For example, `log.sh`
instead of `logging.sh` and `string.sh` instead of `strings.sh`.


### Testing

Every function should be tested:

* Automated tests are in the [test](/test) folder.

* We use [Bats](https://github.com/sstephenson/bats) as our unit test framework for Bash code. Note: Bats has not been
  maintained the last couple years, so we may need to change to the [bats-core](https://github.com/bats-core/bats-core)
  fork at some point (see [#150](https://github.com/sstephenson/bats/issues/150)).

* We run all tests in the [gruntwork/bash-commons-circleci-tests Docker
  image](https://hub.docker.com/r/gruntwork/bash-commons-circleci-tests/) so that (a) it's consistent with how the CI
  server runs them, (b) the tests always run on Linux, (c) any changes the tests make, such as writing files or
  creating OS users, won't affect the host OS, (d) we can replace some of the modules, such as `aws.sh`, with mocks at
  test time. There is a `docker-compose.yml` file in the `test` folder to make it easy to run the tests.

* To run all the tests: `docker-compose up`.

* To run one test file: `docker-compose run tests bats test/array.bats`.

* To leave the Docker container running so you can debug, explore, and interactively run bats: `docker-compose run tests bash`.

* If you ever need to build a new Docker image, the `Dockerfile` is in the [.circleci folder](/.circleci):

    ```bash
    cd .circleci
    docker build -t gruntwork/bash-commons-circleci-tests .
    docker push gruntwork/bash-commons-circleci-tests
    ```



## TODO

1. Add automated tests for `aws.sh` and `aws-wrapper.sh`. We have not tested these as they require either running an
   EC2 Instance or run something like [LocalStack](https://github.com/localstack/localstack).

## License

This code is released under the Apache 2.0 License. Please see 
[LICENSE](https://github.com/gruntwork-io/bash-commons/tree/master/LICENSE) and 
[NOTICE](https://github.com/gruntwork-io/bash-commons/tree/master/NOTICE) for more details.

Copyright &copy; 2018 Gruntwork, Inc.
