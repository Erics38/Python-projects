@echo off
echo Deleting Load Balancer...
aws elbv2 delete-load-balancer --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:027660363574:loadbalancer/app/guestbook-demo-alb/6faeaa4985c608e8

echo Deleting ECS Cluster...
aws ecs delete-cluster --cluster guestbook-demo-cluster

echo Waiting 60 seconds...
ping 127.0.0.1 -n 60 > nul

echo Deleting Security Groups...
aws ec2 delete-security-group --group-id sg-028792c8c94ef606f
aws ec2 delete-security-group --group-id sg-0fc2f3815d1cb5938
aws ec2 delete-security-group --group-id sg-041fa31fa691f7a67
aws ec2 delete-security-group --group-id sg-0dea019db1cf5e281
aws ec2 delete-security-group --group-id sg-07f8e4846fbd1cb09
aws ec2 delete-security-group --group-id sg-084d14595285bef46
aws ec2 delete-security-group --group-id sg-0acc436ef1bdfda04
aws ec2 delete-security-group --group-id sg-0f0982d0c7daa9506
aws ec2 delete-security-group --group-id sg-02500744655eace0e
aws ec2 delete-security-group --group-id sg-04c6e1b416ffc1e97
aws ec2 delete-security-group --group-id sg-049381107305efd58
aws ec2 delete-security-group --group-id sg-0b71d060d822f594c
aws ec2 delete-security-group --group-id sg-0ff2f242e6a1769f9
aws ec2 delete-security-group --group-id sg-022d4c9576df7b3b4
aws ec2 delete-security-group --group-id sg-0f8021a3d13e71048
aws ec2 delete-security-group --group-id sg-0171c2bdc9184cdf7
aws ec2 delete-security-group --group-id sg-0124be826cd2392be
aws ec2 delete-security-group --group-id sg-095c91a6e2928b262
aws ec2 delete-security-group --group-id sg-0c43d4472d891df49
aws ec2 delete-security-group --group-id sg-07b1c1ef7fca5b64b
aws ec2 delete-security-group --group-id sg-06de86f9beafbe024
aws ec2 delete-security-group --group-id sg-0bc30cf3a6d9414f8
aws ec2 delete-security-group --group-id sg-0e0e1a95e338b1bcb
aws ec2 delete-security-group --group-id sg-016ba904be8edc640

echo Cleanup complete!