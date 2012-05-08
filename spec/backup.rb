require 'spec_helper'

describe Backup do
	before(:each) do
		ec2 = double("ec2")
		RightAws::Ec2.stub(:new).and_return(ec2)
		ec2.stub(:describe_instances).and_return(
			[
				{
					:aws_reason=>"", 
					:dns_name=>"ec2-67-202-28-227.compute-1.amazonaws.com", 
					:private_dns_name=>"ip-10-117-42-117.ec2.internal", 
					:ami_launch_index=>"0", 
					:ssh_key_name=>"cattest", 
					:aws_state=>"running", 
					:aws_product_codes=>[], 
					:tags=>{"Name"=>"Testing Instance", "backup-count"=>"1"}, 
					:aws_instance_id=>"i-e7925980", 
					:aws_image_id=>"ami-e565ba8c", 
					:aws_state_code=>16, 
					:aws_instance_type=>"t1.micro", 
					:aws_launch_time=>"2012-04-06T19:42:35.000Z", 
					:aws_availability_zone=>"us-east-1c", 
					:placement_group_name=>"", 
					:aws_kernel_id=>"aki-88aa75e1", 
					:monitoring_state=>"disabled", 
					:private_ip_address=>"10.117.42.117", 
					:ip_address=>"67.202.28.227", 
					:architecture=>"x86_64", 
					:root_device_type=>"ebs", 
					:root_device_name=>"/dev/sda1", 
					:block_device_mappings=>[{:device_name=>"/dev/sda1", :ebs_volume_id=>"vol-aac03dc5", :ebs_status=>"attached", :ebs_attach_time=>"2012-04-06T19:43:01.000Z", :ebs_delete_on_termination=>true}], 
					:virtualization_type=>"paravirtual", 
					:client_token=>"", 
					:aws_owner=>"175776982398", 
					:aws_reservation_id=>"r-6f4a200c", 
					:aws_groups=>["default"]
				}
			]
		)
		ec2.stub(:describe_images).and_return(
		[
			{
				:tags=>{"backup-of" => "i-e3161b89", "backup-epoch" => "1333721272"}, 
				:aws_id=>"aki-00806363", 
				:aws_location=>"karmic-kernel-zul/ubuntu-kernel-2.6.31-300-ec2-i386-20091001-test-04.manifest.xml", 
				:aws_state=>"available", 
				:aws_owner=>"099720109477", 
				:aws_is_public=>true, 
				:aws_architecture=>"i386", 
				:aws_image_type=>"kernel", 
				:root_device_type=>"instance-store", 
				:virtualization_type=>"paravirtual",
				:block_device_mappings=>
    	       	[{:ebs_snapshot_id=>"snap-829a20eb",
             	:ebs_delete_on_termination=>true,
    			:device_name=>"/dev/sda1"}]
			},
			{
				:tags=>{"backup-of" => "i-e3161b89", "backup-epoch" => "1333721273"}, 
				:aws_id=>"aki-00806364", 
				:aws_location=>"karmic-kernel-zul/ubuntu-kernel-2.6.31-300-ec2-i386-20091001-test-04.manifest.xml", 
				:aws_state=>"available", 
				:aws_owner=>"099720109477", 
				:aws_is_public=>true, 
				:aws_architecture=>"i386", 
				:aws_image_type=>"kernel", 
				:root_device_type=>"instance-store", 
				:virtualization_type=>"paravirtual",
				:block_device_mappings=>
    	       	[{:ebs_snapshot_id=>"snap-829a20eb",
             	:ebs_delete_on_termination=>true,
    			:device_name=>"/dev/sda1"}]
			},
			{
				:tags=>{"backup-of" => "i-e3161b89", "backup-epoch" => "1333721274"}, 
				:aws_id=>"aki-00806365", 
				:aws_location=>"karmic-kernel-zul/ubuntu-kernel-2.6.31-300-ec2-i386-20091001-test-04.manifest.xml", 
				:aws_state=>"available", 
				:aws_owner=>"099720109477", 
				:aws_is_public=>true, 
				:aws_architecture=>"i386", 
				:aws_image_type=>"kernel", 
				:root_device_type=>"instance-store", 
				:virtualization_type=>"paravirtual",
				:block_device_mappings=>
    	       	[{:ebs_snapshot_id=>"snap-829a20eb",
             	:ebs_delete_on_termination=>true,
    			:device_name=>"/dev/sda1"}]
			},
			{
				:tags=>{"backup-of" => "i-e3161b89", "backup-epoch" => "1333721275"}, 
				:aws_id=>"aki-00806366", 
				:aws_location=>"karmic-kernel-zul/ubuntu-kernel-2.6.31-300-ec2-i386-20091001-test-04.manifest.xml", 
				:aws_state=>"available", 
				:aws_owner=>"099720109477", 
				:aws_is_public=>true, 
				:aws_architecture=>"i386", 
				:aws_image_type=>"kernel", 
				:root_device_type=>"instance-store", 
				:virtualization_type=>"paravirtual",
				:block_device_mappings=>
    	       	[{:ebs_snapshot_id=>"snap-829a20eb",
             	:ebs_delete_on_termination=>true,
    			:device_name=>"/dev/sda1"}]
			},
			{
				:tags=>{"backup-of" => "i-e3161b89", "backup-epoch" => "1333721276"}, 
				:aws_id=>"aki-00806367", 
				:aws_location=>"karmic-kernel-zul/ubuntu-kernel-2.6.31-300-ec2-i386-20091001-test-04.manifest.xml", 
				:aws_state=>"available", 
				:aws_owner=>"099720109477", 
				:aws_is_public=>true, 
				:aws_architecture=>"i386", 
				:aws_image_type=>"kernel", 
				:root_device_type=>"instance-store", 
				:virtualization_type=>"paravirtual",
				:block_device_mappings=>
    	       	[{:ebs_snapshot_id=>"snap-829a20eb",
             	:ebs_delete_on_termination=>true,
    			:device_name=>"/dev/sda1"}]
			},
			{
				:tags=>{"backup-of" => "i-e3161b89", "backup-epoch" => "1333721277"}, 
				:aws_id=>"aki-00806368", 
				:aws_location=>"karmic-kernel-zul/ubuntu-kernel-2.6.31-300-ec2-i386-20091001-test-04.manifest.xml", 
				:aws_state=>"available", 
				:aws_owner=>"099720109477", 
				:aws_is_public=>true, 
				:aws_architecture=>"i386", 
				:aws_image_type=>"kernel", 
				:root_device_type=>"instance-store", 
				:virtualization_type=>"paravirtual",
				:block_device_mappings=>
    	       	[{:ebs_snapshot_id=>"snap-829a20eb",
             	:ebs_delete_on_termination=>true,
    			:device_name=>"/dev/sda1"}]
			},
			{
				:tags=>{"backup-of" => "i-e3161b89", "backup-epoch" => "1333721278"}, 
				:aws_id=>"aki-00806369", 
				:aws_location=>"karmic-kernel-zul/ubuntu-kernel-2.6.31-300-ec2-i386-20091001-test-04.manifest.xml", 
				:aws_state=>"available", 
				:aws_owner=>"099720109477", 
				:aws_is_public=>true, 
				:aws_architecture=>"i386", 
				:aws_image_type=>"kernel", 
				:root_device_type=>"instance-store", 
				:virtualization_type=>"paravirtual",
				:block_device_mappings=>
    	       	[{:ebs_snapshot_id=>"snap-829a20eb",
             	:ebs_delete_on_termination=>true,
    			:device_name=>"/dev/sda1"}]
			},
		]
		)
		ec2.stub(:create_image).and_return("aki-12345")
		ec2.stub(:create_tags).and_return(true)
		ec2.stub(:deregister_image).and_return(true)
		ec2.stub(:delete_snapshot).and_return(true)
	end

	describe "run!" do
		it "should backup 1 instance correctly" do
			Backup.run!
		end
	end
end