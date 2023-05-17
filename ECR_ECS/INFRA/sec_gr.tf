#grupo de segrança para ALB


resource "aws_security_group" "lb_security" {
 name = "alb_security"
 description = "controls acess to the ALB"
 vpc_id = aws_vpc.my_vpc.id



 ingress {
 from_port = 80
 to_port = 80
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 description = "What does this rule enable"
}


 egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]


 }



 tags = {
 Name = "ALB security Group"
 }
}



# Grupo de seguranca ECS



resource "aws_security_group" "ecs_security" {
 name = "ecs-tasks-security"
 description = "allow inbound acess from Athe LB only"
 vpc_id = aws_vpc.my_vpc.id



 ingress {
 from_port = 80
 to_port = 80
 protocol = "tcp"
 security_groups = [aws_security_group.lb_security.id]
 description = "What does this rule enable"



 }



 egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]

}

 tags = {
 Name = "ECS security Group"
 }
}