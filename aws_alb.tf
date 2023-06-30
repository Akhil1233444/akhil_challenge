
data "aws_instances" "ec2_list" {
   instance_state_names = ["running","pending"]
}



resource "aws_lb_target_group" "CustomTG" {
  name     = "CustomTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id
  target_type = "instance"
  depends_on = [
        aws_instance.web, time_sleep.wait_seconds
    ]
}


resource "time_sleep" "wait" {
      create_duration = "180s"
}



resource "aws_lb_target_group_attachment" "CustomTGAttach" {
  count = 2
  target_group_arn = aws_lb_target_group.CustomTG.arn
  target_id        = "${aws_instance.web[count.index].id}"
  port             = 80
  depends_on = [aws_lb_target_group.CustomTG,time_sleep.wait]
}

resource "aws_lb" "CustomELB" {
  name = "CustomELB"
  subnets = "${aws_subnet.public.*.id}"
  security_groups = [aws_security_group.sg.id]
  tags = {
    Name = "CustomELB"
  }
  depends_on = [
        aws_lb_target_group_attachment.CustomTGAttach
    ]

}


resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = "${aws_lb.CustomELB.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


resource "aws_acm_certificate" "webapp" {
  private_key = "${file("ca.key")}"
  certificate_body = "${file("ca.crt")}"
  certificate_chain = "${file("ca.crt")}"
}


resource "aws_lb_listener" "https" {
  load_balancer_arn = "${aws_lb.CustomELB.arn}"
  certificate_arn = aws_acm_certificate.webapp.arn
  port              = "443"
  protocol          = "HTTPS"
  default_action {
    type = "forward"
    forward {
      target_group {
        arn = "${aws_lb_target_group.CustomTG.arn}"
      }
      stickiness {
        enabled  = true
        duration = 28800
      }
    }
  }
}
