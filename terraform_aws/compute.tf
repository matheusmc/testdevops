
      terraform {
        required_version = ">= 0.12.0"
      }


locals {
  ebs_iops = var.ebs_volume_type == "io1" ? var.ebs_iops : 0
}

# resource "aws_key_pair" "terraform-demo" {
#  key_name   = "var.key_KeyPair"
#  public_key = "${file("/home/brokedba/id_rsa_aws.pub")}"
#}
 #     data  "aws_subnet" "terra_sub" {
    #Required
    #count     = length(data.oci_core_subnet.terrasub.id)
    #subnet_id =lookup(oci_core_subnet.terrasub[count.index],id)
  #  subnet_id =  aws_subnet.terra_sub.id
#}
######################
# INSTANCE
######################
#data "template_file" "user_data" {
#  template = file("../scripts/add-ssh-web-app.yaml")
#}
variable "key_name" { default= "devops"}

/*resource "aws_key_pair" "terra_key" {
   key_name   = var.key_name
   public_key = file("~/id_rsa_aws.pub")
  }*/
 resource "aws_instance" "terra_inst" {
    count         = var.instance_count
    ami                          = var.instance_ami_id["UBUNTU"]
    availability_zone            = data.aws_availability_zones.ad.names[0]
    #cpu_core_count               = 1
    #cpu_threads_per_core         = 1
    disable_api_termination      = false
    ebs_optimized                = false
    get_password_data            = false
    hibernation                  = false
    instance_type                = var.instance_type
   # private_ip                   = var.private_ip
    associate_public_ip_address  = var.map_public_ip_on_launch
    key_name                     = var.key_name
    #key_name = var.key_name
    monitoring                   = false
    secondary_private_ips        = []
    security_groups              = []
    source_dest_check            = true
    subnet_id                    = aws_subnet.terra_sub.id
    user_data                    = filebase64(var.user_data)
    #user_data = filebase64("${path.module}/example.sh") 
    # user_data                   = "${file(var.user_data)}"
    # user_data_base64            = var.user_data_base64
    tags                         = {
       Name = "maquina${count.index}"
    }
    vpc_security_group_ids       = [aws_security_group.terra_sg.id]

    
     dynamic "network_interface" {
    for_each = var.network_interface
    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = lookup(network_interface.value, "network_interface_id", null)
      delete_on_termination = lookup(network_interface.value, "delete_on_termination", true)
    }
  }
    
    credit_specification {
        cpu_credits = "standard"
    }

    metadata_options {
        http_endpoint               = "enabled"
        http_put_response_hop_limit = 1
        http_tokens                 = "optional"
    }

    root_block_device {
        delete_on_termination = true
        encrypted             = false
        iops                  = 100
        volume_size           = 8
    }

    timeouts {}
}
######################
# VOLUME
######################      

  resource "aws_ebs_volume" "terra_vol" {
  count = var.instance_count
  availability_zone = data.aws_availability_zones.ad.names[0]
  size              = var.ebs_volume_size
  iops              = local.ebs_iops
  type              = var.ebs_volume_type
  #tags             = aws_instance.terra_inst.tags/"${var.vol_name}"
  tags              = {
        Name = "dev${count.index}"
  }
}

resource "aws_volume_attachment" "terra_vol_attach" {
 count = var.instance_count
  device_name = var.ebs_device_name[0]
  volume_id   =  aws_ebs_volume.terra_vol[count.index].id
  instance_id =  aws_instance.terra_inst[count.index].id
}