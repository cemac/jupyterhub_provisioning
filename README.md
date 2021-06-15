## JupyterHub Provisioning

This repository contains the Ansible configuration used to provision JupyterHub services.

This configuration is being used with an Ubuntu based system. Other Linux distributions will require adjustments, for example the firewall configuration is managed via `ufw` which may not be available on other distributions.

### Git Submodules

This repository uses git submodules for the following third party Ansible roles:

* Apache: [https://github.com/geerlingguy/ansible-role-apache/](https://github.com/geerlingguy/ansible-role-apache)
* Certbot: [https://github.com/geerlingguy/ansible-role-certbot/](https://github.com/geerlingguy/ansible-role-certbot/)
* UFW: [https://github.com/weareinteractive/ansible-ufw/](https://github.com/weareinteractive/ansible-ufw/)

To obtain the submodules:

```
git submodule init
git submodule update
```

### Overview

Default settings for all hosts are set within the `group_vars/all.yml` file, and host specific settings within the relevant file within `host_vars/`.

The `inventory/hosts.yml` specifies the hosts to which the configuration will be applied, and any host specific settings.

To apply the configuration it is recommended to set up SSH key authentication with the `ansible_user` on the remote host.

Configuration can be applied with Ansible:

```
ansible-playbook -vv -K -i inventory/hosts.yml playbook.yml
```

The `-vv` option increases verbosity, and the `-K` option causes Ansible to prompt for the password for the remote `ansible_user`, to be used for `sudo` access.

Adjust options to your preference.

To try and see what change would be applied, without actually making any changes, the `-C` option can be used:

```
ansible-playbook -C -vv -K -i inventory/hosts.yml playbook.yml
```

### Installing Ansible

Ansible is available via the package manager for many Linux distributions, and can also be installed via pip:

```
$ python3 -m venv ansible
$ . ./ansible/bin/activate
(ansible) $ pip install ansible
```

### Ansible Roles

The following roles are used for the JupyterHub provisioning

#### Certbot

[https://github.com/geerlingguy/ansible-role-certbot/](https://github.com/geerlingguy/ansible-role-certbot/)

The `certbot` role is used to acquire and renew a Let's Encrypt certificate for the system.

The following configuration options are set within `group_vars/all.yml`:

```
certbot_auto_renew: true
certbot_auto_renew_user: 'root'
certbot_auto_renew_hour: '04'
certbot_auto_renew_minute: '57'
certbot_auto_renew_options: '--quiet --no-self-upgrade'
certbot_create_if_missing: true
certbot_create_method: 'standalone'
certbot_create_standalone_stop_services: []
```

These settings will attempt to request / create a certificate if one does not exist, and run a `cron` job to automatically renew the certificate each day.


The following settings can be applied at the host level:

```
certbot_certs:
   - email: 'name@example.com'
     domains:
       - 'jupyterhub.example.com'
```

#### Resources

The `resources` role is used to create various resources on the remote system, such as directories, users and to install packages.

For example, in the `group_vars/all.yml`, the `ssl-cert` package is installed:

```
resources_packages_default:
  - name: 'ssl-cert'
```

A default `.bashrc` file is also copied to the remote system:

```
resources_copies_default:
  # Default .bashrc:
  - src: 'files/etc/skel/.bashrc'
    dest: '/etc/skel/.bashrc'
```

At the host level, this role may be used to create users:

```
resources_users_host:
  - name: 'user00'
    shell: '/bin/bash'
  - name: 'user01'
  - name: 'user02'
```

The `roles/resources/defaults/main.yml` specifies various default options for the different resources.

#### UFW

[https://github.com/weareinteractive/ansible-ufw/](https://github.com/weareinteractive/ansible-ufw/)

The `ufw` role is used to set up firewall roles on the remote system.

Default rules, including SSH and HTTP access, are configure in the `group_vars/all.yml` file:

```
ufw_rules:
  - port: '22'
    rule: 'allow'
    comment: 'Allow SSH'
  - port: '80'
    rule: 'allow'
    comment: 'Allow HTTP'
  - port: '443'
    rule: 'allow'
    comment: 'Allow HTTPS'
```

#### Miniconda

The `miniconda` role is used to install Anaconda Python.

By default, this role will download `Miniconda3-latest-Linux-x86_64.sh` (if a new install is to be performed), and install within the specified directory.

Additional channels, packages to be installed (either via `conda` or `pip`), and whether the installation should be updated can be specified in the configuration:

```
miniconda_installs:
  # jupyterhub1234:
  - path: '/opt/jupyterhub1234/conda'
    user: 'root'
    user_home: '/root'
    updates: true
    channels:
      - 'conda-forge'
    packages:
      - 'jupyterhub'
      - 'notebook'
      - 'sudospawner'
    wrap: true
    wrapper_dir: '/opt/jupyterhub1234/bin'
    wrap_executables:
      - 'python'
      - 'jupyterhub'
```

The user as which the installer should be run can be specified with the `user` parameter.

If requested, specific executables can be accessed via a wrapper scipt in a spearate location. In this example, the Miniconda installation would be located within `/opt/jupyterhub1234/conda`, with wrappers for `python` and `jupyterhub` at `/opt/jupyterhub1234/bin/python` and `/opt/jupyterhub1234/bin/jupyterhub`.

#### Jupyterhub

The `jupyterhub` role is used to configure JupyterHub instances.

The role can be used to create JupyterHub instances which use either the [sudo](https://github.com/jupyterhub/sudospawner/) or [systemd](https://github.com/jupyterhub/systemdspawner) spawners, and use either local authentication, or Microsoft Auzure authentication, via [OAuth](https://github.com/jupyterhub/oauthenticator).

The role can create the configuration and systemd service files for the JupyterHub, and enable / start the service.

```
  - name: 'jupyterhub4567'
    python_dir: '/opt/jupyterhub4567'
    spawner:
      name: 'systemd'
    user:
      name: 'jupyterhub_jupyterhub4567'
      home: '/var/lib/jupyterhub_jupyterhub4567'
    auth:
      name: 'azure'
      tenant_id: 'common'
      callback_url: 'https://jupyterhub.example.com/jupyterhub4567/hub/oauth_callback'
      client_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
      client_secret: 'xxx'
    api_port: '2051'
    bind_port: '2041'
    port: '2030'
    users:
      users:
        - 'user00'
        - 'user04'
        - 'user05'
        - 'user06'
      admins:
        - 'user00'
    data_dirs:
      - path: '/data/jupyterhub4567'
```

This example would use a Python install within `/opt/jupyterhub4567`, configure the service to use the systemd spawner, with a working directory (where JupyterHub stores SQLite state files) of `/var/lib/jupyterhub_jupyterhub4567`, and authenticate users via Microsoft Azure. The specified users would be be added to a local group on the system, which is used to allow access to the service, and the specified admin users would be granted admin access to the service. The data directory `/data/jupyterhub4567` would be created with permissions to allow access for the specified users of this service.

#### Apache

[https://github.com/geerlingguy/ansible-role-apache/](https://github.com/geerlingguy/ansible-role-apache)

The `apache` role configures the the Apache service, which manages the connection to the JupyterHub instances running on the system.

In the example configurations, two JupyterHub instances are created, which would be accessed via the addresses `https://jupyterhub.example.com/jupyterhub1234/` and `https://jupyterhub.example.com/jupyterhub1234/`.

The configuration uses the Apache `mod_proxy` to handle the connections to and from the JupyterHub instances.
