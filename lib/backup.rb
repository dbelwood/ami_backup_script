require 'yaml'
require 'logger'
require 'right_aws'

class Backup
	@@aws_access_key = ''
	@@aws_secret_key = ''
	@@backup_tag = ''
	@@source_region = ''
	@@target_regions = []
	@@logger = nil

	@@region_kernel_id_map = {
		'us-east-1' => [
			'aki-88aa75e1',
			'',
			'',
			''
		],
		'us-west-1' => [
			'',
			'',
			'',
			''
		],
		'us-west-2' => [
			'',
			'',
			'',
			''
		],
		'eu-west-1' => [
			'',
			'',
			'',
			''
		],
		'ap-southeast-1' => [
			'',
			'',
			'',
			''
		],
		'ap-northeast-1' => [
			'',
			'',
			'',
			''
		],
		'sa-east-1' => [
			'',
			'',
			'',
			''
		],
		'us-gov-west-1' => [
			'',
			'',
			'',
			''
		]
	}

	def self.run! (arguments = nil)
		begin
			# Load config vars
			config = YAML.load File.read(File.join(File.dirname(__FILE__), '../conf/backup.yml'))
			@@aws_access_key = config["AWS_ACCESS_KEY"]
			@@aws_secret_key = config["AWS_SECRET_ACCESS_KEY"]
			@@backup_tag = config["BACKUP_TAG"]
			log_file = config["LOG_FILE"]
			@@source_region = config["SOURCE_REGION"]
			@@target_regions = config["TARGET_REGIONS"]

			# Parse command-line arguments
			if !arguments.nil?
			  arguments.each do |argument|
			    case argument
			      when "--help"
			      	usage
			      when /--log-file=(.*)/
			      	log_file = argument.sub('--log-file=', '')

			      when "--verbose"
			      	log_file = STDOUT
			      else 
			      	puts "Unknown argument #{argument}. Use '--help'."
			      	exit(false)
			    end
			  end
			end

			# Start logger
			@@logger = Logger.new log_file

			# Create images
			create_images
		rescue StandardError => e
			puts e
			puts e.backtrace.to_s
			exit(false)
		end
	end

	# Usage
	def self.usage
	  puts 'Usage: backup [options]'
	  puts 'Options:'

	  puts "  --help\t\t- this message"
	  puts "  --log-file=LOG_FILE\t- write log to LOG_FILE"
	  puts "  --verbose\t\t- verbose mode (overrides '--log-file' argument)"
	  exit 0
	end

	def self.create_images
		@ec2 = RightAws::Ec2.new(@@aws_access_key, @@aws_secret_key, {:logger => @@logger, :connections => :dedicated})
		instances_to_sync = []
		begin
			@ec2.describe_instances(:filters => {'tag-key' => @@backup_tag}).each do |instance|
				begin
					ami_id = create_image @ec2, instance
					clean_up_images @ec2, instance
				rescue RightAws::AwsError => e
					@@logger.error "Error creating image - " + e.message
				end

				instances_to_sync << instance		
			end
			sync_instances instances_to_sync
		rescue RightAws::AwsError => e
			@@logger.error "Error describing instances - " + e.message
		end
	end

	def self.create_image(ec2, instance)
		current_date = Time.now.strftime('%Y-%m-%d')
		epoch_time = Time.now().to_i.to_s
		# Generate new AMI name
	    # AMI names must be between 3 and 128 characters long, and may contain letters, numbers, '(', ')', '.', '-', ' ' and '_'
	    if instance[:tags]['Name']
	      instance_name = instance[:tags]['Name'].gsub(/[^A-Za-z0-9\(\)\.\-\_\ ]/, '').slice(0..127)
	    else
	      instance_name = instance[:aws_instance_id]
	    end
	    ami_name = instance_name + '/' + current_date + "-" + epoch_time

		# Generate new AMI description
	    ami_description = @@backup_tag + '; '
	    ami_description += 'AZ:'     + instance[:aws_availability_zone] + '; '
	    ami_description += 'TYPE:'   + instance[:aws_instance_type] + '; '

	    ami_description += 'IP:'     + instance[:ip_address] + '; '
	    ami_description += 'KEY:'    + instance[:ssh_key_name] + '; '
	    ami_description += 'GROUPS:' + instance[:aws_groups].join(',')

		# Create image
		ami_id = ec2.create_image(instance[:aws_instance_id], :name => ami_name, :description => ami_description.slice(0..254), :no_reboot => true)
		@@logger.info "AMI #{ami_name} created successfuly. ID: #{ami_id}."
		# Tag image { backup-of, backup-epoch }
		begin
			ec2.create_tags(ami_id, {"backup-of" => instance[:aws_instance_id], "backup-epoch" => epoch_time})
			@@logger.info "AMI #{ami_id} tagged with backup-of #{instance[:aws_instance_id]} and backup-epoch of #{epoch_time}"
		rescue RightAws::AwsError => e
			@@logger.error "Error creating tags - " + e.message
		end

		ami_id
	end

	def self.clean_up_images(ec2, instance)
		backup_count = instance[:tags][@@backup_tag].to_i
		begin
			images = ec2.describe_images(:filters => {'tag:backup-of' => instance[:aws_instance_id]})
			images.sort{|x,y| x[:tags]['backup-epoch'] <=> y[:tags]['backup-epoch']}
			if images.size > backup_count
				images.slice!(0, images.size - backup_count).each do |image|
					begin
						remove_image(image) 
					rescue RightAws::AwsError => e
						@@logger.error "Error removing image - " + e.message
					end		
				end
			end
			images_to_migrate << ami_id
		rescue RightAws::AwsError => e
			@@logger.error "Error describing images - " + e.message
		end	
	end

	def self.remove_image(ec2, image)
		# De-register image
		ec2.deregister_image image[:aws_id]
		@@logger.info "AMI #{image[:name]} deregistered. ID: #{image[:aws_id]}."

		# Remove image snapshots
		image[:block_device_mappings].each do |snapshot|
			begin
				ec2.delete_snapshot(snapshot[:ebs_snapshot_id])
				@@logger.info "Snapshot #{snapshot} removed."
			rescue RightAws::AwsError => e
				@@logger.error "Error deleting snapshot - " + e.message
			end
		end
	end

	def self.clone_instance(source_ec2, target_ec2, instance)
		# Create from image
		# Loop through connected ebs-volumes
		source_ec2.describe_volumes(instance[:aws_instance_id]).each do |volume|
			# Create volume
			target_ec2.create_volume '', volume[:aws_size], volume[:zone]

			# 
		end

		# Start analogous instance

		
	end

	def self.sync_instance(source_ec2, target_ec2, instance)
		# Does instance already exist in target region
		#images = ec2.describe_images(:filters => {'tag:regional-backup-of' => instance[:tags]["backup-uid"]})
		instances = target_ec2.describe_instances (:filters => {'tag:regional-backup-of' => instance[:tags]["backup-uid"]})
		if instances.size > 0
			# Instance running
			instance = instances[0]

			# Load instance from image
			target_ec2.start_instance instance[:aws_instance_id]
		else
			# Create instance
			# Clone instance to new region
			self.clone_instance source_ec2, target_ec2, instance
		end
	end

	def self.sync_instances(source_ec2, instances)
		@@target_regions.each do |region|
			target_ec2 = RightAws::Ec2.new(@@aws_access_key, @@aws_secret_key, {:region => region, :logger => @@logger, :connections => :dedicated})
			instances.each do |instance|
				sync_instance source_ec2, target_ec2, instance
				#@@logger.info "AMI image #{image_id} migrated to #{region}"
			end
		end
	end
end