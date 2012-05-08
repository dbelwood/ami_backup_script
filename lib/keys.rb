require 'connection'
require 'configuration'
require 'openssl'

class Keys
	def self.run! (arguments = nil)
		Configuration::init(true)
		regions = nil
		# Parse command-line arguments
		if !arguments.nil?
			arguments.each do |argument|
		    	case argument
		      	when "--help"
		      		usage
		      	when /--regions=(.*)/
		      		regions = (argument.sub('--regions=', '')).split(',')
		      		regions.map {|region| region.strip!}
		      	else 
		      		puts "Unknown argument #{argument}. Use '--help'."
		      		exit(false)
		      	end
		    end
		    puts "insufficient args" if regions.nil?
		    generate_keys regions
		end
	end

	private
	def self.generate_keys regions
		# Make sure key file exists, create if it doesn't
		file_name = File.join(File.dirname(__FILE__), '../pems/'+Configuration::key_name)
		if (!File.exists? file_name)
			result = `ssh-keygen -f #{file_name} -t rsa -P ""`
		end

		# Import key into region
		key_data = `cat #{file_name}.pub`
		#Configuration::logger.info key_data
		regions.each do |region|
			Configuration::logger.info "Importing keypair to #{region}"
			Connection.get_connection(region).import_key_pair Configuration::key_name, key_data
			Configuration::logger.info "done."
		end
	end
end