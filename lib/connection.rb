require 'configuration'
require 'right_aws'

module Connection
	@@region_conn_map = {}
		
	def self.get_connection region
		create_connection region unless @@region_conn_map.has_key? region
		@@region_conn_map[region]
	end

	private
	def self.create_connection region
		@@region_conn_map[region] = RightAws::Ec2.new(Configuration::access_key, Configuration::secret_access_key, {:region => region, :logger => Configuration::logger, :connections => :dedicated})
	end
end