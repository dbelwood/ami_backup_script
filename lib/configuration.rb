module Configuration
	@@initialized = false
	@@aws = nil
	@@images = nil
	@@sync_settings = nil
	@@logger = nil
	@@defaults = nil

	# AWS Settings
	def self.access_key
		init unless initialized?
		@@aws["AWS_ACCESS_KEY"]
	end

	def self.secret_access_key
		init unless initialized?
		@@aws["AWS_SECRET_ACCESS_KEY"]
	end

	# Logger
	def self.logger override=nil
		init unless initialized?
		@@logger
	end

	def self.set_verbose_mode

	end

	# Provision settings
	def self.get_ami_id region, os, arch
		@@logger.info "Get AMI Id for region #{region} os #{os} and arch #{arch}"
		@@images[region][os][arch]
	end

	# Backup settings


	# Sync settings
	def self.key_name
		init unless initialized?
		@@sync_settings["KEY_NAME"]
	end

	def self.directories_to_sync
		init unless initialized?
		@@sync_settings["whitelist_directories"].join(" ")
	end

	def self.initialized?
		@@initialized
	end

	def self.init(verbose=false)
		@@aws = YAML.load File.read(File.join(File.dirname(__FILE__), '../conf/aws.yml'))
		@@images = YAML.load File.read(File.join(File.dirname(__FILE__), '../conf/images.yml'))
		@@sync_settings = YAML.load File.read(File.join(File.dirname(__FILE__), '../conf/sync.yml'))
		@@defaults = YAML.load File.read(File.join(File.dirname(__FILE__), '../conf/defaults.yml'))
		if verbose
			@@logger = Logger.new STDOUT
		else
			@@logger = Logger.new  @@defaults["LOG_FILE"]
		end
		@@initialized = true
	end
end