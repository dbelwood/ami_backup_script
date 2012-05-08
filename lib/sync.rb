require 'connection'
require 'configuration'
require 'ssh'

# This library syncs existing instances between regions
class Sync
	def self.run! (arguments = nil)
		Configuration::init(true)
		source_region, instance_id, target_region = nil
		# Parse command-line arguments
		if !arguments.nil?
			arguments.each do |argument|
		    	case argument
		      	when "--help"
		      		usage
		      	when /--instance_id=(.*)/
		      		instance_id = argument.sub('--instance_id=', '')

		      	when /--source_region=(.*)/
		      		source_region = argument.sub('--source_region=', '')

		      	when /--target_region=(.*)/
		      		target_region = argument.sub('--target_region=', '')

		      	else 
		      		puts "Unknown argument #{argument}. Use '--help'."
		      		exit(false)
		      	end
		    end
		    puts "insufficient args" if (source_region.nil? || instance_id.nil? || target_region.nil?)
		    provision_instance source_region, instance_id, target_region
			usage
		end
	end

	# Usage
	def self.usage
	  puts 'Usage: sync --instance_id <instance_id> --source_region <source_region> --target_region <target_region>** All options are required'
	  puts 'Options:'

	  puts "  --help\t\t- this message"
	  puts "  --instance_id\t\t- id of instance to provision"
	  puts "  --source_region\t- region where instance exists"
	  puts "  --target_region\t- region to provision instance"
	  exit 0
	end

	def self.gen_keys
	end

	private
	def self.sync_instance  source_region, instance_id, target_region, user_name
		# Create EC2 connections
		source_conn = Connection::get_connection source_region
		target_conn = Connection::get_connection target_region

		source_instance = source_conn.describe_instances(instance_id)[0]
		target_instance = target_conn.describe_instances(:filters => {'tag:copy_of_instance' => source_instance[:aws_instance_id]})[0]
		target_instance = target_conn.start_instances(target_instance[:aws_instance_id])[0]
		ensure_instance_running target_conn, target_instance[:aws_instance_id]

		pem_file = File.join(File.dirname(__FILE__), '../pems/#{Configuration::key_name}.pem')
		directories = Configuration::directories_to_sync
		Net::SSH.start(source_instance[:dns_name], user_name, {:keys => [pem_file]}) do |ssh|
			ssh.exec("rsync PHAZax --rsh 'ssh -i #{pem_file}' --rsync-path 'sudo rsync' #{directories} #{user_name}@#{target_instance[:private_dns_name]}:/") do |ch, stream, data|
				if stream == :stderr
    				Configuration::logger.error "ERROR: #{data}"
    				exit(0)
  				else
    				Configuration::logger.info "Successfully synced data."
  				end
			end
		end
	end

	def self.ensure_instance_running connection, instance_id
		running = false
		until running
			running = (connection.describe_instances(instance_id)[0][:aws_state] == "running")
			sleep 10 unless running
		end
	end
end