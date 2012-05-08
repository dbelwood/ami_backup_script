require 'yaml'
require 'logger'
require 'connection'
require 'configuration'

class Backup
	def self.run! (arguments = nil)
		begin
			Configuration::init(true)
			region = nil
			# Parse command-line arguments
			if !arguments.nil?
			  arguments.each do |argument|
			    case argument
			      when "--help"
			      	usage
			      when "--region"
			      	region = argument.sub('--region=', '')
			      else 
			      	puts "Unknown argument #{argument}. Use '--help'."
			      	exit(false)
			    end
			  end
			end

			# Create images
			create_images region
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
	  exit 0
	end

	def self.create_images
		# Create EC2 connections
		conn = Connection::get_connection region
		instances_to_sync = []
		begin
			conn.describe_instances(:filters => {'tag-key' => @@backup_tag}).each do |instance|
				begin
					ami_id = create_image conn, instance
					clean_up_images conn, instance
				rescue RightAws::AwsError => e
					Configuration::logger.error "Error creating image - " + e.message
				end
			end
		rescue RightAws::AwsError => e
			Configuration::logger.error "Error describing instances - " + e.message
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
		Configuration::logger.info "AMI #{ami_name} created successfuly. ID: #{ami_id}."
		# Tag image { backup-of, backup-epoch }
		begin
			ec2.create_tags(ami_id, {"backup-of" => instance[:aws_instance_id], "backup-epoch" => epoch_time})
			Configuration::logger.info "AMI #{ami_id} tagged with backup-of #{instance[:aws_instance_id]} and backup-epoch of #{epoch_time}"
		rescue RightAws::AwsError => e
			Configuration::logger.error "Error creating tags - " + e.message
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
						Configuration::logger.error "Error removing image - " + e.message
					end		
				end
			end
			images_to_migrate << ami_id
		rescue RightAws::AwsError => e
			Configuration::logger.error "Error describing images - " + e.message
		end	
	end

	def self.remove_image(ec2, image)
		# De-register image
		ec2.deregister_image image[:aws_id]
		Configuration::logger.info "AMI #{image[:name]} deregistered. ID: #{image[:aws_id]}."

		# Remove image snapshots
		image[:block_device_mappings].each do |snapshot|
			begin
				ec2.delete_snapshot(snapshot[:ebs_snapshot_id])
				Configuration::logger.info "Snapshot #{snapshot} removed."
			rescue RightAws::AwsError => e
				Configuration::logger.error "Error deleting snapshot - " + e.message
			end
		end
	end
end