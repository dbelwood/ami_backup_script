require 'connection'
require 'configuration'

# This library provisions running instances from one region to 1-n regions
class Provision
	def self.run! (arguments = nil)
		Configuration::init(true)
		source_region, instance_id, target_region, target_az, os, key_name = nil
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

		      	when /--target_az=(.*)/
		      		target_az = argument.sub('--target_az=', '')

		      	when /--os=(.*)/
		      		os = argument.sub('--os=', '')

		      	when /--key_name=(.*)/
		      		key_name = argument.sub('--key_name=', '')
		      	else 
		      		puts "Unknown argument #{argument}. Use '--help'."
		      		exit(false)
		      	end
		    end
		    puts "insufficient args" if (source_region.nil? || instance_id.nil? || target_region.nil? || target_az.nil? || os.nil? || key_name.nil?)
		    provision_instance source_region, instance_id, target_region, target_az, os, key_name
		else
			usage
		end
	end

	# Usage
	def self.usage
	  puts 'Usage: provision --instance_id <instance_id> --source_region <source_region> --target_region <target_region> --target_az <availability_zone> --os <os> ** All options are required'
	  puts 'Options:'

	  puts "  --help\t\t- this message"
	  puts "  --instance_id\t\t- id of instance to provision"
	  puts "  --source_region\t- region where instance exists"
	  puts "  --target_region\t- region to provision instance"
	  puts "  --target_az\t\t- availability zone to provision instance"
	  puts "  --os\t\t\t- os type of image, ubuntu, centos, etc."
	  exit 0
	end

	private
	def self.provision_instance source_region, instance_id, target_region, target_az, os, key_name
		created_volumes = {}

		# Create EC2 connections
		source_conn = Connection::get_connection source_region
		target_conn = Connection::get_connection target_region

		# Pull instance metadata
		Configuration::logger.info "Retrieve instance metadata"
		instance = source_conn.describe_instances(instance_id)[0]
		ami_id = Configuration::get_ami_id target_region, os, instance[:architecture]
		Configuration::logger.info "Image id: #{ami_id}"

		# Create volumes based on non-root block devices on instance
		Configuration::logger.info "Retrieve instance block device mappings"
		instance[:block_device_mappings].each do |mapping|
			if (mapping[:device_name] != instance[:root_device_name] && mapping[:ebs_status] == "attached")
				# Describe source volume
				volume = source_conn.describe_volumes(:filters => {'volume-id' => mapping[:ebs_volume_id]})[0]

				# Create volume
				created_volume = target_conn.create_volume("", volume[:aws_size], target_az)
				created_volume[:aws_device] = volume[:aws_device]
				created_volumes[created_volume[:aws_id]] = created_volume
				Configuration::logger.info "Volume #{volume[:aws_id]} with size #{volume[:aws_size]} Gib created."
			end
		end

		# Start instance based on source instance
		Configuration::logger.info "Launching instance in target region"
		target_instance = target_conn.launch_instances(ami_id, :availability_zone => target_az, :key_name => key_name, :instance_type => instance[:aws_instance_type])[0]

		# Wait for volumes to be created
		Configuration::logger.info "Waiting for created volumes to become available"
		ensure_volumes_ready target_conn, created_volumes.keys

		# Tag instance for future sync'ing
		Configuration::logger.info "Pushing source tags to target"
		tags = instance[:tags]
		Configuration::logger.info "Tagging target instance for future syncing - copy_of_instance => #{instance[:aws_id]}"
		tags["copy_of_instance"] = instance[:aws_instance_id]
		Configuration::logger.info target_instance
		target_conn.create_tags target_instance[:aws_instance_id], tags 

		Configuration::logger.info "Ensuring instance running"
		ensure_instance_running target_conn, target_instance[:aws_instance_id]

		# Attach volumes
		Configuration::logger.info "Attaching volumes"
		created_volumes.values.each do |volume|
			Configuration::logger.info volume
			target_conn.attach_volume volume[:aws_id], target_instance[:aws_instance_id], volume[:aws_device]
		end

		# Stop instance
		Configuration::logger.info "Stopping instance"
		target_conn.stop_instances target_instance[:aws_instance_id]

		Configuration::logger.info "done.  You will now need to start the target instance and "
	end

	def self.ensure_volumes_ready connection, volume_ids
		volumes_to_process = volume_ids
		while volumes_to_process.size > 0 do
			volumes_to_process = connection.describe_volumes volumes_to_process, :filters => {'attachment.status' => 'creating'}
			sleep 20 if volumes_to_process.size > 0
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