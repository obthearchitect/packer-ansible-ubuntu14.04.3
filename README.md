# Packer Example - Ubuntu 14.04.3 LTS Vagrant Box using Ansible provisioner

## Overview

**Current Ubuntu OS Used**: 14.04.3 LTS (Trusty)

This packer build installs and configures Ubuntu 14.04.3 LTS x86 using Ansible, and then generates three Vagrant box files, for:

  - VirtualBox (ISO/OVF)
  - Amazon Web Services (AWS)
  - DigitalOcean

This build can be modified to meet your specific requirements. From leveraging more provisioners, configuring additional post-processors or narrowing down specific builders, the sky's the limits so pack it in. I hope that you find this sample build helpful and that it trims down your learning curve to getting started with the these awesome tools!

## Motivation 
My current job role allows me to help customers in many different areas of technology. From architecting & deploying large scale Cisco UCS Clusters that serve up HPC workloads to building out highly available & scalable microservices architectures in AWS. But the best part of my job is being able to engage with customers to understand their needs & challenges and to help solve them. Over the last year there's been a significant surge in customers looking to introduce or improve their current DevOps toolset. Most recently, I've had requests for template & configuration management so I put on my geek hat to learn 2 very popular tools for this requirement: Packer & Ansible. Grab a brew and let's get started. 

## Requirements
The following software must be **installed/present** on your local machine **before** you can use Packer to build the Vagrant box file:

  - [Packer](http://www.packer.io/) - Packer is a tool for creating machine and container images for multiple platforms from a single source configuration.
  - [Vagrant](http://vagrantup.com/) - Vagrant is a tool for building complete development environments. With an easy-to-use workflow and focus on automation, Vagrant lowers development environment setup time, increases development/production parity, and makes the "works on my machine" excuse a relic of the past.
    + [Vagrant AWS Provider](https://github.com/mitchellh/vagrant-aws) - This is a Vagrant provider plugin that supports the management of instances in EC2 or VPCs.
    + [Vagrant DigitalOcean Provider](https://github.com/smdahlen/vagrant-digitalocean) This is a Vagrant provider plugin that supports the management of DigitalOcean droplets (instances).
  - [VirtualBox](https://www.virtualbox.org/) - VirtualBox is a general-purpose full virtualizer for x86 hardware, targeted at server, desktop and embedded use.
  - [Ansible](http://docs.ansible.com/intro_installation.html) - Ansible is a free software platform for configuring and managing computers. It combines multi-node software deployment, ad hoc task execution, and configuration management. It manages nodes over SSH or PowerShell.

You will also need some Ansible roles installed so they can be used to configure the VM with our webserver tools and New Relic for monitoring. I'll talk more about roles in the `Ansible` section of this document.   

To install the roles:

  1. Run `$ ansible-galaxy install -r requirements.txt` withinin this directory. This will download and install the 2 roles defined, `newrelic` and `apache2` to your local machine. 
  2. If your local Ansible roles path is not the default (`/etc/ansible/roles`), update the `role_paths` inside `ubuntu1404.json` to match your custom location.

## Folder Structure
<pre>├── LICENSE - # Free for all to use, modify, & redistribute
├── README.md - # You're reading it duh!
├── ansible - # Stores Ansibles Playbooks or Roles
│   └── webserver.yml - # Contains our playbook to kick off role based  provisioning from the roles you downloaded earlier
├── http - # Stores our Kickstarts/Preseeds for a clean install
│   └── preseed.cfg
├── scripts - # Stores our bash scripts
│   ├── ansible.sh - # Installs Ansible PPA & Ansible
│   ├── base.sh - # Updates machine with the latest packages & tweaks SSH
│   ├── cleanup.sh - # Cleans up already installed package binaries & TMP
│   ├── vagrant.sh - # Installs Vagrant SSH Key
│   ├── virtualbox.sh - # Installs Virtualbox Guest Utilities
│   └── zerodisk.sh - # Zeros out disk
├── ubuntu-web-template.json - # The almighty! Runs our Packer build job
└── vagrant_templates - # Holds Vagrant Box specific configurations
    ├── vagrantfile-aws.template - # Contains AWS specific deployment info (Instance Type, Region, etc)
    ├── vagrantfile-digitalocean.template - # Contains DigitalOcean specific deployment info (Droplet Size, Region, etc)
    └── vagrantfile-virtualbox.template - # Contains DigitalOcean specific deployment info
</pre>

## Packer Template Info & Walkthrough

`Templates` - This is where all the magic happens, one file to rule to them all. This is the single JSON file that defines the provisioning and configuration of all machine images across multiple platforms (AWS, Virtualbox, DigitalOcan). In here we list out our variables, provisioner's, builders, and post processors. Packer is able to read our template and create multiple machine images in one shot in parallel. 

`Variables` - This is where we allow our template to be further configured without hardcoding values. This lets us parameterize our templates so that we can keep secret tokens, environment-specific data, and other types of information out of our templates. This maximizes the portability and share-ability of the template. In our template we used environmental variables for AWS & DigitalOcean access keys, and user variables for ISO Information, Usernames/Passwords. You can move this section to it's own JSON file and call it using `packer build -var-file=my_vars.json ubuntu-web-template.json`. Do note in order to be successful with the AWS/DigitalOcean build you must a) create your environmental variables on your local machine; b) convert them over to user variables and define them directly in the template; c) don't use variables and just define them right in their key/value pairs. Option `A` is the most secure.

`Provisioners` - These are the workhorses of Packer and where alot of the awesome sauce happens! They install and configure software within a running machine prior to that machine being turned into a static image. Some provisioner's include Ansible, Shell Scripts, and Puppet; they are processed in the order that they're listed. In our template we first call a set of shell scripts that perform system updates and install Ansible, followed by running an Ansible Playbook that configures our machine, and finally another set of shell scripts to clean things up. One thing you'll notice is an `overrides` section. Overrides allow us to configure each build separately which can be useful for a number of reasons. In our template we want `virtualbox-guest-utils` to only be installed on the virtualbox builds, but not the amazon-ebs build. By overriding we're able to pass along a specific provisioner set of tasks for that build. 

`Builders` tell Packer where/what to create our machine images for. The builders in our template include Amazon EC2, DigitalOcean, Virtualbox-ISO, and Virtualbox-OVF. 

`Post-processors` allow us to take the result of a builder or another post-processor and process that to create a new `artifact`. Artifacts are the results of a single build, and are usually a set of IDs or files to represent a machine image. Every builder produces a single artifact.  An example of a post-processor is Vagrant that takes a build and converts the artifact into a valid Vagrant box. We used this post-processor in our template so we can use Vagrant to spin up/down our machines and we also assigned specific vagrantfile templates (found in `vagrant_templates`)for those boxes.

## Ansible Info & Walkthrough
Ansible is one of the most popular and easiest configuration management tools to get into. The official description of it from the docs page that it's an IT automation tool. It can configure systems, deploy software, and orchestrate more advanced IT tasks such as continuous deployments or zero downtime rolling updates. Unlike other alternatives, Ansible is installed on a single host, in our case it will be our local machine, and uses SSH to communicate with each remote host. It is incredibly easy to use and understand, since it uses [playbooks](https://docs.ansible.com/ansible/playbooks_intro.html) in [yaml](https://docs.ansible.com/ansible/YAMLSyntax.html) format using a simple module based syntax. This module based approach is what makes getting started with Ansible so appealing. You don't need years of scripting experience to be able to manage a small to enterprised size environment. 

`Playbooks` are Ansible’s configuration file in YAML format that define a set of tasks to run for configuration provisioning. Within the playbook you'll have a `task` or a list of tasks. A task is nothing more than a call to an Ansible module. 

`Modules` (also referred to as “task plugins” or “library plugins”) are the ones that do the actual work in Ansible, they are what gets executed in each playbook task. 

For this build we used Ansible `roles` to configure our machines. Roles are a further level of abstraction that can be useful for organizing playbooks. As you add more and more functionality and flexibility to your playbooks, they can become unwieldy and difficult to maintain as a single file. Roles allow you to create very minimal playbooks that then look to a directory structure to determine the actual configuration steps they need to perform. Originally I had all these configuration steps built into a single playbook but by breaking it up it allows me to define which role(s) a server should get. 

If you wanted to manually install the roles you can run the following commands: 

`ansible-galaxy install ovidioborrero.apache2` - Installs Apache2, Git, Wget, Php5, Php5-GD, and Curl. 

`ansible-galaxy install ovidioborrero.newrelic` - Installs the New Relic Server Monitoring agent for Linux

Alternatively if you wanted to view and fork/clone to further tweak the roles to meet your requirements or to simply learn more about how the roles are configured, you can visit the following Github Repos: [apache2](https://github.com/obthearchitect/ansible-role-apache2) & [New Relic](https://github.com/obthearchitect/ansible-role-newrelic)

In our roles we use the following modules: 

 - **[Apt](https://docs.ansible.com/ansible/apt_module.html)** - Manages `apt` packages on our Ubuntu installation and allows us to install Apache, Git, and PHP5.
 - **[Apt-Repository](https://docs.ansible.com/ansible/apt_repository_module.html)** - Adds our `apt` repository for New Relic.
 - **[Apt-Key](https://docs.ansible.com/ansible/apt_key_module.html)** - Adds our signed New Relic `apt` key so we can download the New Relic Server for Linux agent. 
 - **[Template](https://docs.ansible.com/ansible/template_module.html)** - Template files contain our template variables for New Relic, based on Python's Jinja2 template engine.
 - **[Git](https://docs.ansible.com/ansible/git_module.html)** - Allows us to leverage `git` to clone in our `hello world` repo.  
 - **[File](https://docs.ansible.com/ansible/file_module.html)** - Allows us remove and create directories as well as symlinks for our document root. 
 - **[Replace](https://docs.ansible.com/ansible/replace_module.html)** - This module will replace all instances of a pattern within a file. In our template we use this to point our document root to `/var/www/html`
 - **[Service](https://docs.ansible.com/ansible/service_module.html)** - This module controls services and allows us to make sure that Apache is set to start on boot.

So you can see how easy it is to work with Ansible roles let's examine our `main.yml` file found in the `./ansible` directory:
<pre>
---
- hosts: all
  sudo: yes
  gather_facts: yes

  roles:
    - ovidioborrero.apache2
    - { role: ovidioborrero.newrelic, newrelic_license_key: REPLACE_WITH_YOUR_KEY_HERE }

</pre>
The `hosts: all` declaration at the top, tells Ansible that we'll be running this play for every host or in the context of Packer for that specific build instance. Next we tell it to `sudo` to elevate permissions so we can install our software. Next we define our roles. In this example, we tell Ansible to use the roles we downloaded earlier found in the `requirements.txt` file. The second line `- { role: ovidioborrero.newrelic, newrelic_license_key: REPLACE_WITH_YOUR_KEY_HERE }` tells Ansible to pass in a variable for our New Relic License key to the template file. As a reminder, to learn more about how the roles are configured, you can visit the following Github Repos: [apache2](https://github.com/obthearchitect/ansible-role-apache2) & [New Relic](https://github.com/obthearchitect/ansible-role-newrelic) to break them down. 

## Packer Usage
Make sure all the required software (listed above) is installed, then cd to the directory containing the `ubuntu-web-template.json` file. 

If you want to quickly learn about the template without having to dive into the JSON itself you can use the `inspect` parameter.  

    $ packer inspect ubuntu-web-template.json

The first thing you'll want to do is configure the variables section. Variables allow us to maximize the portability and shareability of the template. You can store the variables directly within the template, define them from the CLI when you call packer, or set them up as environmental variables on your local computer. 

For more information on variables please see visit the following [Packer Docs](https://packer.io/docs/templates/user-variables.html) page.

Next up, you can tweak the options for the `builders` within the template. For example, you may want to change the instance type and AMI for AWS or you may want to use a different Droplet or Region for your DigitalOcean build. You can make those changes directly under those builders or you can even make those user defined variables and move the values up the stack. It's completely up to you and what your preference is. 

If you don't want to use a specific builder you can either a) delete that/those builders from the builder section or b) omit it when we run packer build (I'll show you this below).

**If you plan to run the AWS builder and use Vagrant to launch an instance from your template you'll have to tweak the `./vagrant_templates/vagrantfile-aws.template` file.** 

Here's what you'll need to modify: 
<pre>
  aws.access_key_id = ENV['AWS_ACCESS_KEY_ID']
  aws.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
  aws.keypair_name = "YOUR_KEY"
  aws.instance_type = "CHOOSE_INSTANCE_SIZE"
  aws.block_device_mapping = [{ 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 50 }]
  aws.tags = {
    'Name' => 'WHATEVER',
    'Environment' => 'YOUWANT'
  }
  aws.subnet_id = "subnet-XXXX"
  aws.security_groups = "sg-XXXX"
  aws.associate_public_ip = "true"
  override.ssh.username = "SSH_USERNAME"
  override.ssh.private_key_path = "/PATH/TO/YOUR/KEY"
</pre>

To run the full build: 

    $ packer build ubuntu-web-template.json

After a few minutes, Packer should tell you that the build was successful and you have new artifacts. 

<pre>==> Builds finished. The artifacts of successful builds are:</pre>

If you want to **only build specific boxes** for one of the supported visualization platforms (e.g. only build the Amazon Instance), add `--only=amazon-ebs` to the `packer build` command:

    $ packer build --only=amazon-ebs ubuntu-web-template.json

or you could also do something like this:

    $ packer build --only=amazon-ebs,virtualbox-ovf,digitalocean ubuntu-web-template.json

If you want to **only build specific boxes except** for one of the supported virtualization platforms, add `--except=amazon-ebs` to the `packer build` command:

    $ packer build --except=amazon-ebs ubuntu-web-template.json

or you could also do something like this:

    $ packer build --except=amazon-ebs,virtualbox-ovf,digitalocean ubuntu-web-template.json

To access your **Virtualbox via Vagrant**, cd to the `vagrant_boxes` directory and then from there run the following commands:

    $ vagrant box add --name=YOUR_BOX_NAME virtualbox-ubuntu_64.box
    $ mkdir /path/to/folder/for/vagrant/box
    $ vagrant init YOUR_BOX_NAME
    $ vagrant up
    $ vagrant ssh

To access your **AWS Box via Vagrant**, cd to the `vangrant_boxes` directory and then from there run the following commands:

*Note that you must have the Vagrant AWS Provider Plugin installed, as well as the Dummy Box, and lastly need to have configured the `./vagrant_templates/vagrantfile-aws.template` before attempting to launch in AWS. Please go the requirements section to get these resources* 

    $ mkdir -p /path/to/new/folder/for/vagrant/box && cp aws-ubuntu_64.box "$_"
    $ cd /path/to/folder/for/vagrant/box
    $ tar xvf aws-ubuntu_64.box
    $ vagrant up
    $ vagrant ssh

## Contributing
If you'd you like to make any tweaks to make this better for the rest of the community please submit a pull request with your update. 

1. Fork it
2. Create your feature branch `git checkout -b my-new-feature`
3. Commit your changes `git commit -am 'Add some feature'`
4. Push to the branch `git push origin my-new-feature`
5. Create new Pull Request

## Credits
Shout out to [geerlingguy](https://github.com/geerlingguy/packer-ubuntu-1404) for the inspiration on his Centos & Ansible Role based example. Be sure to check out his other repos, lots of goodies in there!

## License
This build is released under the MIT license.

## Author Information
Ovidio Borrero
