# -*- mode: ruby -*-
# vi: set ft=ruby :


# Used for IP sequencing
require 'ipaddr'
require 'erb'
require 'yaml'
require 'find'
require 'logger'


VAGRANTFILE_API_VERSION = '2'
PROVISIONER_HOSTNAME = Socket.gethostname[/^[^.]+/]
APPLICATION_NAME = ENV['VAGRANT_TOOLS_APP_NAME'] || 'VAGRANT_TOOLS'
ANSIBLE_ROOT_PATH = '/etc/ansible'
# TODO: make this use ansible_root_path
ANSIBLE_INVENTORY_PATH = ENV['VAGRANT_TOOLS_ANSIBLE_INVENTORY_PATH'] || '/etc/ansible/inventory/vagrant_tools'


# Required for logger to print to both file and stdout
class MultiIO
  def initialize(*targets)
    @targets = targets
  end

  def write(*args)
    @targets.each {|t| t.write(*args)}
  end

  def close
    @targets.each(&:close)
  end
end


# Setup the Ruby logger
LOGGER_LEVELS = %w[DEBUG INFO WARN ERROR FATAL UNKNOWN].freeze
log_file = File.open('vagrant_tools.log', 'a')
logger = Logger.new(MultiIO.new(STDOUT, log_file), shift_size = 1048576)
#level ||= LOGGER_LEVELS.index ENV.fetch("#{VAGRANT_TOOLS_LOG_LEVEL}", 'WARN')
level ||= LOGGER_LEVELS.index ENV['VAGRANT_TOOLS_LOG_LEVEL'] || 'WARN'
level ||= Logger::WARN
logger.level = level
# TODO: parameterize below
logger.progname = 'vagrant_tools'
logger.info("logger initialized with level: <#{logger.level}>")


# Log miscellaneous values
logger.info("Vagrantfile API version: <#{VAGRANTFILE_API_VERSION}>")
logger.info("Provisioner hostname: <#{PROVISIONER_HOSTNAME}>")


# When importing hashes from yaml, all keys are strings instead of symbols --
# in order to have consistent key referencing throughout, requires conversion
def convert_hash_keys_to_symbols(hash)
  hash.keys.each do | key |
    hash[(key.to_sym rescue key) || key] = hash.delete(key)
    if defined?(logger)
      logger.debug("[<#{key}>]  Defaults key converted from string to symbol")
    end
  end
end
    

# Create defaults file from example if defaults is missing
unless File.file?('core/definitions/defaults.yaml.erb')
  FileUtils.cp('core/definitions/example-defaults.yaml.erb', 'core/definitions/defaults.yaml.erb')
  unless File.file?('config/definitions/main.yaml.erb')
    FileUtils.cp('config/definitions/example-main.yaml.erb', 'config/definitions/main.yaml.erb')
  end
end


defaults = ERB.new File.read 'core/definitions/defaults.yaml.erb'
logger.info('Defaults ERB file loaded')
logger.debug("defaults: <#{defaults}>")
defaults = YAML.load defaults.result binding
logger.info('Defaults converted from ERB to YAML')
logger.debug("defaults: <#{defaults}>")





# Convert dictionary keys from strings to symbols (which are more efficient);
# Required because YAML.load will always use strings as keys
#defaults.keys.each do | key |
#  defaults[(key.to_sym rescue key) || key] = defaults.delete(key)
#  logger.debug("[<#{key}>]  Defaults key converted from string to symbol")
#end
convert_hash_keys_to_symbols(defaults)
# Need to manually target nested hashes until a recursive solution is found
defaults[:script_jobs].each do | job |
  logger.debug("Passing script job for symbol conversion: <#{job}>")
  convert_hash_keys_to_symbols(job)
end

logger.info('Defaults string keys converted to symbols')
logger.debug("defaults: <#{defaults}>")


# Read through machine definition files
machines = []
known_machine_names = []
Dir.glob('config/definitions/*.erb') do |file|
  next if file == '.' or file == '..' or file.include? 'example'
  logger.info("Reading definition file <#{file}>")
  logger.info("[<#{file}>]  Reading definition from file")
  definitions = ERB.new File.read file
  logger.info("[<#{file}>]  Definitions file loaded as ERB")
  logger.debug("[<#{file}>]  definitions: <#{definitions}>")
  definitions = YAML.load definitions.result binding
  logger.info("[<#{file}>]  Definitions converted from ERB to YAML")
  logger.debug("[<#{file}>]  definitions: <#{definitions}>")
  definitions.each do | definition |
    logger.info("Reading definition <#{definition['name'] || definition[:name] || '(no name)'}>")
    # Convert dictionary keys from strings to symbols
    definition.keys.each do | key | 
      definition[(key.to_sym rescue key) || key] = definition.delete(key)
      logger.debug("Converted key from string to symbol: <#{key}>")
    end
    if known_machine_names.include? definition[:name]
      logger.warn("Duplicate definition name detected: <#{definition[:name]}>!")
      machines.each do | machine |
        if machine[:name] == definition[:name]
          machine.merge(definition)
          logger.info("Merged definition with existing machine: <#{definition[:name]}>")
          break
        end
      end
    else
      machines.push(definition)
      logger.info("Added definition to machine list: <#{definition[:name] || '(no name)'}>")
      known_machine_names.push(definition[:name])
      logger.info("Added definition name to list of known machine names: <#{definition[:name]}>")
    end
  end
end
logger.info("Finished processing machine definitions: <#{machines}>")


# Configure each machine according to definition data
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  logger.info('Machine/s configuration started')
  
  machines.each do | machine |
    logger.info("Configuring machine: <#{machine[:name] || defaults[:name]}>")

    machine = defaults.merge(machine)
    logger.info("[<#{machine[:name]}>]  Merged machine attributes with default values")
    logger.debug("Machine attributes: <#{machine}>")

    machine[:iterations].times do | iteration |
      logger.info("[<#{machine[:name]}>]  Iterating machine: <#{iteration}>")

      unless machine[:iterations] = 1
        logger.debug("[<#{machine[:name]}>]  Machine iterations (<#{machine[:iterations]}>) greater than 1")
        machine[:name] = "#{machine[:name]}-0#{iteration+1}"
        logger.info("Machine name changed: <#{machine[:name]}>")
      end

      config.vm.define machine[:name] do | node |
        
        node.vm.provider machine[:provider] do | node |
          node.name = machine[:name]
          logger.info("Machine name configured: <#{node.name}>")
        end
        logger.info("[<#{machine[:name]}>]  Machine provider-specific configurations applied: <#{machine[:provider]}>")

        node.vm.box = machine[:box]
        logger.info("[<#{machine[:name]}>]  Machine box configured: <#{node.vm.box}>")

        node.vm.hostname = "#{machine[:name]}.#{machine[:domain_name]}"
        logger.info("[<#{machine[:name]}>]  Machine hostname configured: <#{node.vm.hostname}>")

        if machine[:network_address] == 'dhcp'
          node.vm.network machine[:network_category], type: 'dhcp'
          logger.info("[<#{machine[:name]}>]  Machine configured for DHCP with <#{machine[:network_category]}>")
        else
          # Do hacky things to iterate the IP Address
          iteration.times do
            machine[:network_address] = IPAddr.new(machine[:network_address].to_s).succ().to_s
            logger.info("[<#{machine[:name]}>]  Machine IP Address iterated by one step: <#{machine[:network_address]}>")
          end
          node.vm.network machine[:network_category], ip: machine[:network_address]
          #logger.info("TESTTEST #{node.vm.network}")
          logger.info("[<#{machine[:name]}>]  Machine network category configured: <#{machine[:network_category]}>")
          logger.info("[<#{machine[:name]}>]  Machine network address configured: <#{machine[:network_address]}>")
        end

        unless machine[:base_mac] == nil
          logger.debug("[<#{machine[:name]}>]  Configuring machine base MAC address: <#{machine[:base_mac]}>")
          node.vm.base_mac  = machine[:base_mac]
          logger.info("[<#{machine[:name]}>]  Machine base MAC address configured: <#{node.vm.base_mac}>")
        end

        # Define node default shell
        config.ssh.shell = machine[:shell]
        logger.info("[<#{machine[:name]}>]  Machine shell configured: <#{config.ssh.shell}>")

        logger.debug("[<#{machine[:name]}>]  Configuring machine file-copy jobs: <#{machine[:copy_jobs]}>")
        machine[:copy_jobs].each do | job |
          logger.debug("[<#{machine[:name]}>]  Configuring machine file-copy job: <#{job}>")
          node.vm.provision 'file', source: job[:source], destination: job[:destination]
          logger.debug("[<#{machine[:name]}>]  Machine file-copy job configured: <#{job}>")
        end
        logger.info('[<#{machine[:name]}>]  Machine file-copy jobs configured')

        logger.debug("[<#{machine[:name]}>]  Configuring machine folder-sync jobs: <#{machine[:sync_jobs]}>")
        machine[:sync_jobs].each do | job |
          node.vm.synced_folder job[:source], job[:destination], owner: job[:owner], group: job[:group], disabled: job[:disabled]
          logger.debug("[<#{machine[:name]}>]  Machine folder-sync job configured: <#{job}>")
        end
        logger.info('[<#{machine[:name]}>]  Machine folder-sync jobs configured')

        machine[:script_jobs].each do | job |
          logger.debug("[<#{machine[:name]}>] Working on script-job: <#{job}>")
          # FIXME: this line doesn't work with the symbol source, why?
          #job[:name] ||= File.basename(job[:source], ".*")
          job[:name] ||= File.basename(job['source'], ".*")
          if job[:args]
            node.vm.provision :shell, path: job[:source], name: job[:name]
          else
            node.vm.provision :shell, path: job[:source], name: job[:name]
          end
          logger.debug("[<#{machine[:name]}>]  Machine script job configured: <#{job}>")
        end
        logger.info('[<#{machine[:name]}>]  Machine script jobs configured')

        machine[:shell_jobs].each do | job |
          node.vm.provision :shell, inline: job
          logger.debug("[<#{machine[:name]}>]  Machine shell job configured: <#{job}>")
        end
        logger.info('[<#{machine[:name]}>]  Machine shell jobs configured')

        logger.info("[<#{machine[:name]}>]  Running Ansible playbooks on machine")
        machine[:ansible_playbooks].each do | playbook |
          config.vm.provision :ansible do | ansible |
            if defined? VAGRANT_TOOLS_LOG_LEVEL and VAGRANT_TOOLS_LOG_LEVEL  == 'DEBUG'
              ansible.verbose = true
            else
              ansible.verbose = false
            end
            ansible.extra_vars = { ansible_ssh_user: 'vagrant' }
            logger.debug("[<#{machine[:name]}>]  Ansible extra_vars set: <#{ansible.extra_vars}>")
            ansible.inventory_path = ANSIBLE_INVENTORY_PATH
            logger.debug("[<#{machine[:name]}>]  Ansible inventory_path set: <#{ansible.inventory_path}>")
            #ansible.playbook = "/etc/ansible/playbooks/#{playbook}"
            ansible.playbook = "#{ANSIBLE_ROOT_PATH}/playbooks/#{playbook}"
            logger.debug("[<#{machine[:name]}>]  Ansible playbook configured: <#{ansible.playbook}>")
          end
        end
        logger.info("[<#{machine[:name]}>]  Ansible playbooks completed")
      end
      logger.info("[<#{machine[:name]}>]  Machine configuration completed (iteration)")
    end
    logger.info("[<#{machine[:name]}>]  Machine configuration completed (total)")
  end
  logger.info('Configuration complete for all machines')
end
logger.info('Vagrant configuration complete')
