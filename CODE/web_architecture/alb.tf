resource "aws_lb" "main" {
    name               = "${var.project_name}-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb.id]
    subnets            = aws_subnet.public[*].id  # wildcard is used to span multi az 
    
    tags = { Name = "${var.project_name}-alb" }
} 


# Target Group = the pool of EC2 instances the ALB sends traffic to,
# plus the rules for what "healthy" means.


resource "aws_lb_target_group" "web" {
           name         = "${var.project_name}-tg"
           port         = 80
           protocol     = "HTTP"
           vpc_id       = aws_vpc.main.id

           health_check {
            path                = "/"
            protocol            = "HTTP"
            healthy_threshold   = 2  #2 consecutive successes = healthy
            unhealthy_threshold = 2  # 2 consecutive failures = unhealthy, pull from rotation
            timeout             = 5
            interval            = 30
            matcher             = "200"

           }

           tags = { Name = "${var.project_name}-tg" }
}

# Listener = "when a request hits the ALB on port 80, what do I do
# with it?" Here: forward it to the target group above.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Register each EC2 instance into the target group.
# count = 2 loops this over both instances created in ec2.tf.
resource "aws_lb_target_group_attachment" "web" {
  count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
