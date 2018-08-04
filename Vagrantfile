# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'open3'


DIR = File.dirname(__FILE__)


PROVISIONER = 'shell'
PROVISION_ROOT_PATH = "#{DIR}/provision"
REMOTE_SOURCE_PATH_LINUX = '/tmp/provision'
REMOTE_SOURCE_PATH_WIN = 'C:\\tmp\\provision'
MOUNT_PATH_LINUX = '/mnt/host'
MOUNT_PATH_WIN = 'C:\\host'
COMMON_PROVISION_SCRIPTS_LINUX = [ 'common-dependencies_centos.sh' ]
COMMON_PROVISION_SCRIPTS_WIN = [ 'common-dependencies_win.bat' ]


load "#{DIR}/conf.env"


Vagrant.configure('2') do |config|

    if Vagrant.has_plugin?('vagrant-cachier')
        config.cache.scope = :machine
    end


    config.vm.box = 'centos/7'
    config.vm.box_version = '1804.02'


    dhcpServerIP = "#{PRIVATE_NETWORK_SLASH24_PREFIX}.1"
    internalNetworkName = "jenkins-ha-setup"
    cliArgs = [
        '--netname', internalNetworkName,
        '--ip', dhcpServerIP,
        '--netmask', '255.255.255.0',
        '--lowerip', "#{PRIVATE_NETWORK_SLASH24_PREFIX}.100",
        '--upperip', "#{PRIVATE_NETWORK_SLASH24_PREFIX}.200",
        '--enable'
    ]

    if ARGV[0] == 'up'
        stdout, stderr, status = Open3.capture3(
            [ 'vboxmanage', 'dhcpserver', 'add' ].concat(cliArgs).join(' ')
        )

        if stderr.length > 0
            puts("NOTE: DHCP server for network: #{internalNetworkName} already exists. Overwriting configurations...")
            stdout, stderr, status = Open3.capture3(
                [ 'vboxmanage', 'dhcpserver', 'modify' ].concat(cliArgs).join(' ')
            )
        end
    end


    ADDITIONAL_GLUSTER_NODES_INDEX = "#{MOUNT_PATH_LINUX}/gluster-nodes-list.txt"
    ADDITIONAL_GLUSTER_NODES > 0 && (1..ADDITIONAL_GLUSTER_NODES).each do |i|
        config.vm.define "gluster-node-#{i}" do |node|

            hostname = "gluster-node-#{i}"

            provision_scripts = Array.new(COMMON_PROVISION_SCRIPTS_LINUX).push(
                'resolve.sh',
                'gluster-node.sh',
                "gluster-additional-node_configuration.sh #{ADDITIONAL_GLUSTER_NODES_INDEX}"
            )
            asset_files = [
                './../conf.env'
            ]

            # node.vm.box = 'centos/7'

            node.vm.provider 'virtualbox' do |vb|
              vb.name = "#{PREFIX}_#{hostname}"
              vb.memory = 1024
              vb.cpus = 1
            end

            node.vm.hostname = hostname
            node.vm.provision 'shell', inline: 'sed -i -e "/^127.0.0.1\\t"$(hostname)"/d" /etc/hosts', privileged: true
            node.vm.network 'private_network',
                            type: 'dhcp',
                            virtualbox__intnet: internalNetworkName,
                            :adapter => 2

            node.vm.synced_folder "#{DIR}", '/vagrant', disabled: true
            node.vm.synced_folder PROVISION_ROOT_PATH, MOUNT_PATH_LINUX, type: 'virtualbox'

            asset_files.each do |relFilePath|
                filename = File.basename(relFilePath)
                node.vm.provision 'file',
                                  source: "#{PROVISION_ROOT_PATH}/#{relFilePath}",
                                  destination: "#{REMOTE_SOURCE_PATH_LINUX}/#{filename}"
            end
            provision_scripts.each do |script|
                filename = script.split(' ').first
                node.vm.provision 'file',
                                  source: "#{PROVISION_ROOT_PATH}/#{PROVISIONER}/#{filename}",
                                  destination: "#{REMOTE_SOURCE_PATH_LINUX}/#{filename}"
            end

            provision_scripts.each do |script|
              node.vm.provision PROVISIONER,
                                inline: "#{REMOTE_SOURCE_PATH_LINUX}/#{script}",
                                privileged: true
            end

        end
    end


    config.vm.define "gluster-node-0" do |node|

        ipSuffix = 21
        instance_ip = "#{PRIVATE_NETWORK_SLASH24_PREFIX}.#{ipSuffix}"
        hostname = "gluster-node-0"

        provision_scripts = Array.new(COMMON_PROVISION_SCRIPTS_LINUX).push(
            'resolve.sh',
            'gluster-node.sh',
            "gluster-initial-node_configuration.sh #{ADDITIONAL_GLUSTER_NODES_INDEX}"
        )
        asset_files = [
            './../conf.env'
        ]

        # node.vm.box = 'centos/7'

        node.vm.provider 'virtualbox' do |vb|
          vb.name = "#{PREFIX}_#{hostname}"
          vb.memory = 1024
          vb.cpus = 1
        end

        node.vm.hostname = hostname
        node.vm.provision 'shell', inline: 'sed -i -e "/^127.0.0.1\\t"$(hostname)"/d" /etc/hosts', privileged: true
        node.vm.network 'private_network',
                        ip: instance_ip,
                        virtualbox__intnet: internalNetworkName,
                        :adapter => 2

        node.vm.synced_folder "#{DIR}", '/vagrant', disabled: true
        node.vm.synced_folder PROVISION_ROOT_PATH, MOUNT_PATH_LINUX, type: 'virtualbox'

        asset_files.each do |relFilePath|
            filename = File.basename(relFilePath)
            node.vm.provision 'file',
                              source: "#{PROVISION_ROOT_PATH}/#{relFilePath}",
                              destination: "#{REMOTE_SOURCE_PATH_LINUX}/#{filename}"
        end
        provision_scripts.each do |script|
            filename = script.split(' ').first
            node.vm.provision 'file',
                              source: "#{PROVISION_ROOT_PATH}/#{PROVISIONER}/#{filename}",
                              destination: "#{REMOTE_SOURCE_PATH_LINUX}/#{filename}"
        end

        provision_scripts.each do |script|
          node.vm.provision PROVISIONER,
                            inline: "#{REMOTE_SOURCE_PATH_LINUX}/#{script}",
                            privileged: true
        end

    end


    JENKINS_MASTERS = [ 1, 2 ]
    JENKINS_MASTERS.each do |i|
        config.vm.define "jenkins-master-#{i}" do |node|

            ipSuffix = 30 + i
            instance_ip = "#{PRIVATE_NETWORK_SLASH24_PREFIX}.#{ipSuffix}"
            hostname = "jenkins-master-#{i}"

            provision_scripts = Array.new(COMMON_PROVISION_SCRIPTS_LINUX).push(
                'resolve.sh',
                'jenkins-master.sh',
                'cluster.sh'
            )
            if i == 1
                provision_scripts.push( 'jenkins-master_configuration.sh' )
            elsif i == JENKINS_MASTERS.length
                provision_scripts.push( 'cluster_configuration.sh' )
            end
            asset_files = [
                './../conf.env',
                './../jenkins/config.xml_template',
                './../jenkins/jenkins.model.JenkinsLocationConfiguration.xml_template',
                './../jenkins/example-job.xml',
                './../jenkins/plugin-list.txt',
                './../jenkins/var-lib-jenkins.mount'
            ]

            # node.vm.box = 'centos/7'

            node.vm.provider 'virtualbox' do |vb|
              vb.name = "#{PREFIX}_jenkins-master-#{i}"
              vb.memory = 1024
              vb.cpus = 1
            end

            node.vm.hostname = hostname
            # NOTE: when setting a hostname with vagrant, it also makes the system resolving its
            # hostname to localhost, which gets reverted with this statement
            node.vm.provision 'shell', inline: 'sed -i -e "/^127.0.0.1\\t"$(hostname)"/d" /etc/hosts', privileged: true
            node.vm.network 'private_network',
                            ip: instance_ip,
                            virtualbox__intnet: internalNetworkName,
                            :adapter => 2

            node.vm.synced_folder "#{DIR}", '/vagrant', disabled: true
            node.vm.synced_folder PROVISION_ROOT_PATH, MOUNT_PATH_LINUX, type: 'virtualbox'

            asset_files.each do |relFilePath|
                filename = File.basename(relFilePath)
                node.vm.provision 'file',
                                  source: "#{PROVISION_ROOT_PATH}/#{relFilePath}",
                                  destination: "#{REMOTE_SOURCE_PATH_LINUX}/#{filename}"
            end
            provision_scripts.each do |script|
                filename = script.split(' ').first
                node.vm.provision 'file',
                                  source: "#{PROVISION_ROOT_PATH}/#{PROVISIONER}/#{filename}",
                                  destination: "#{REMOTE_SOURCE_PATH_LINUX}/#{filename}"
            end

            provision_scripts.each do |script|
              node.vm.provision PROVISIONER,
                                inline: "#{REMOTE_SOURCE_PATH_LINUX}/#{script}",
                                privileged: true
            end
        end
    end


    if CREATE_LOAD_BALANCER
        config.vm.define "load-balancer" do |node|

            ipSuffix = 11
            instance_ip = "#{PRIVATE_NETWORK_SLASH24_PREFIX}.#{ipSuffix}"
            hostname = "load-balancer"

            provision_scripts = Array.new(COMMON_PROVISION_SCRIPTS_LINUX).push(
                'resolve.sh',
                'haproxy.sh',
                'haproxy_configuration.sh'
            )
            asset_files = [
                './../conf.env',
                './../haproxy/haproxy.cfg_template',
                './../haproxy/haproxy_template',
            ]

            # node.vm.box = 'centos/7'

            node.vm.provider "virtualbox" do |vb|
              vb.name = "#{PREFIX}_load-balancer"
              vb.memory = 512
              vb.cpus = 1
            end

            node.vm.hostname = hostname
            node.vm.provision 'shell', inline: 'sed -i -e "/^127.0.0.1\\t"$(hostname)"/d" /etc/hosts', privileged: true
            node.vm.network 'private_network',
                            ip: instance_ip,
                            virtualbox__intnet: internalNetworkName,
                            :adapter => 2
            if EXTERNAL_LOAD_BALANCER_IP
                node.vm.network "private_network",
                                ip: "#{EXTERNAL_LOAD_BALANCER_IP}",
                                :adapter => 3
                node.vm.network "forwarded_port",
                                guest: "#{EXTERNAL_LOAD_BALANCER_PORT}",
                                host: "#{EXTERNAL_LOAD_BALANCER_PORT}",
                                :adapter => 3
            end

            node.vm.synced_folder "#{DIR}", "/vagrant", disabled: true
            node.vm.synced_folder PROVISION_ROOT_PATH, MOUNT_PATH_LINUX, type: "virtualbox"

            asset_files.each do |relFilePath|
                filename = File.basename(relFilePath)
                node.vm.provision 'file',
                                  source: "#{PROVISION_ROOT_PATH}/#{relFilePath}",
                                  destination: "#{REMOTE_SOURCE_PATH_LINUX}/#{filename}"
            end
            provision_scripts.each do |script|
                filename = script.split(' ').first
                node.vm.provision 'file',
                                  source: "#{PROVISION_ROOT_PATH}/#{PROVISIONER}/#{filename}",
                                  destination: "#{REMOTE_SOURCE_PATH_LINUX}/#{filename}"
            end

            provision_scripts.each do |script|
              node.vm.provision PROVISIONER,
                                inline: "#{REMOTE_SOURCE_PATH_LINUX}/#{script}",
                                privileged: true
            end

        end
    end


    LINUX_AGENTS > 0 && (1..LINUX_AGENTS).each do |i|
        config.vm.define "jenkins-agent-linux-#{i}" do |node|

            hostname = "jenkins-agent-linux-#{i}"

            provision_scripts = Array.new(COMMON_PROVISION_SCRIPTS_LINUX).push(
                'jenkins-agent_linux.sh'
            )
            asset_files = [
                './../conf.env',
                './../jenkins/jenkins-swarm.service'
            ]

            # node.vm.box = 'centos/7'

            node.vm.provider 'virtualbox' do |vb|
              vb.name = "#{PREFIX}_jenkins-agent-linux-#{i}"
              vb.memory = 1024
              vb.cpus = 1
            end

            node.vm.hostname = hostname
            node.vm.provision 'shell', inline: 'sed -i -e "/^127.0.0.1\\t"$(hostname)"/d" /etc/hosts', privileged: true
            node.vm.network 'private_network',
                            type: 'dhcp',
                            virtualbox__intnet: internalNetworkName,
                            :adapter => 2

            node.vm.synced_folder "#{DIR}", '/vagrant', disabled: true
            node.vm.synced_folder PROVISION_ROOT_PATH, MOUNT_PATH_LINUX, type: 'virtualbox'

            asset_files.each do |relFilePath|
                filename = File.basename(relFilePath)
                node.vm.provision 'file',
                                  source: "#{PROVISION_ROOT_PATH}/#{relFilePath}",
                                  destination: "#{REMOTE_SOURCE_PATH_LINUX}/#{filename}"
            end
            provision_scripts.each do |script|
                filename = script.split(' ').first
                node.vm.provision 'file',
                                  source: "#{PROVISION_ROOT_PATH}/#{PROVISIONER}/#{filename}",
                                  destination: "#{REMOTE_SOURCE_PATH_LINUX}/#{filename}"
            end

            provision_scripts.each do |script|
              node.vm.provision PROVISIONER,
                                inline: "#{REMOTE_SOURCE_PATH_LINUX}/#{script}",
                                privileged: true
            end
        end
    end


    WINDOWS_AGENTS > 0 && (1..WINDOWS_AGENTS).each do |i|
        config.vm.define "jenkins-agent-win-#{i}" do |node|

            hostname = "jenkins-agent-win-#{i}"

            provision_scripts = Array.new(COMMON_PROVISION_SCRIPTS_WIN).push(
                {
                    :filename => 'jenkins-agent_win.bat',
                    :args => [ PRIVATE_NETWORK_SLASH24_PREFIX ]
                }
            )
            asset_files = [
                './../conf.env',
                './assets/win/secconfig.cfg',
                './../jenkins/jenkins-swarm-service.bat_template'
            ]

            node.vm.box = 'opentable/win-2012r2-standard-amd64-nocm'
            config.vm.box_version = nil

            node.vm.communicator = 'winrm'

            node.vm.provider 'virtualbox' do |vb|
                vb.name = "#{PREFIX}_jenkins-agent-win-#{i}"
                vb.cpus = 1
                vb.memory = 2048
                vb.customize ['modifyvm', :id, '--memory', '2048']
                vb.customize ['modifyvm', :id, '--vram', '16']
                vb.gui = ! START_WINDOWS_AGENTS_HEADLESS
            end

            # Dont know yet if necessary
            # node.vm.communicator = "winrm"

            node.vm.hostname = hostname
            node.vm.network 'private_network',
                            type: 'dhcp',
                            :adapter => 2
            node.vm.provider 'virtualbox' do |vb|
                vb.customize [ 'modifyvm', :id, '--nic2', 'intnet' ]
                vb.customize [ 'modifyvm', :id, '--nictype2', '82540EM' ]
                vb.customize [ 'modifyvm', :id, '--intnet2', internalNetworkName ]
                vb.customize [ 'modifyvm', :id, '--cableconnected2', 'on' ]
            end
            node.vm.network 'forwarded_port', guest: 3389, host: 3389
            node.windows.set_work_network = true

            node.vm.synced_folder "#{DIR}", '/vagrant', disabled: true
            node.vm.synced_folder PROVISION_ROOT_PATH, MOUNT_PATH_WIN, type: 'virtualbox'

            asset_files.each do |relFilePath|
                filename = File.basename(relFilePath)
                node.vm.provision 'file',
                                  source: "#{PROVISION_ROOT_PATH}/#{relFilePath}",
                                  destination: "#{REMOTE_SOURCE_PATH_WIN}/#{filename}"
            end

            # convert conf.env and make it work with windows
            node.vm.provision 'shell',
                              path: "#{PROVISION_ROOT_PATH}/assets/win/convert-configuration-file_win.ps1",
                              privileged: true,
                              args: [
                                  "#{REMOTE_SOURCE_PATH_WIN}\\conf.env"
                              ]

            # # NOTE: install chocolatey
            node.vm.provision 'shell',
                              privileged: true,
                              inline: "Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"

            provision_scripts.each do |script|
                if script.is_a? String
                    filename = script
                    arguments = []
                elsif script.is_a? Object
                    filename = script[:filename]
                    arguments = script[:arguments] || []
                end
                node.vm.provision PROVISIONER,
                                  path: "#{PROVISION_ROOT_PATH}/#{PROVISIONER}/#{filename}",
                                  upload_path: "#{REMOTE_SOURCE_PATH_WIN}\\#{filename}",
                                  privileged: true,
                                  args: arguments
            end

        end
    end

end
