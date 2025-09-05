@echo off
echo === FINAL CLEANUP - DELETE VPC ENDPOINTS FIRST ===

echo Deleting VPC Endpoints...
aws ec2 delete-vpc-endpoint --vpc-endpoint-id vpce-0493c3861946cc498
aws ec2 delete-vpc-endpoint --vpc-endpoint-id vpce-0b3e317778eac1680
aws ec2 delete-vpc-endpoint --vpc-endpoint-id vpce-0e459d5bf448cccf6
aws ec2 delete-vpc-endpoint --vpc-endpoint-id vpce-0808e9913d8649f2c
aws ec2 delete-vpc-endpoint --vpc-endpoint-id vpce-010da817aee6224b1
aws ec2 delete-vpc-endpoint --vpc-endpoint-id vpce-0cc288f0f9afd72fc
aws ec2 delete-vpc-endpoint --vpc-endpoint-id vpce-0da3dabdd344326b3
aws ec2 delete-vpc-endpoint --vpc-endpoint-id vpce-09cf33b0711c0b922
aws ec2 delete-vpc-endpoint --vpc-endpoint-id vpce-0b739c810a9ffe66d
aws ec2 delete-vpc-endpoint --vpc-endpoint-id vpce-033b8c168801c869f

echo Waiting 30 seconds for VPC endpoints to delete...
ping 127.0.0.1 -n 30 > nul

echo Deleting remaining security groups...
aws ec2 delete-security-group --group-id sg-041fa31fa691f7a67
aws ec2 delete-security-group --group-id sg-0dea019db1cf5e281
aws ec2 delete-security-group --group-id sg-07f8e4846fbd1cb09
aws ec2 delete-security-group --group-id sg-0171c2bdc9184cdf7
aws ec2 delete-security-group --group-id sg-0124be826cd2392be
aws ec2 delete-security-group --group-id sg-095c91a6e2928b262
aws ec2 delete-security-group --group-id sg-0c43d4472d891df49
aws ec2 delete-security-group --group-id sg-07b1c1ef7fca5b64b
aws ec2 delete-security-group --group-id sg-04c6e1b416ffc1e97
aws ec2 delete-security-group --group-id sg-06de86f9beafbe024
aws ec2 delete-security-group --group-id sg-0bc30cf3a6d9414f8
aws ec2 delete-security-group --group-id sg-0b71d060d822f594c

echo Deleting VPCs...
aws ec2 delete-vpc --vpc-id vpc-0899032133b559e32
aws ec2 delete-vpc --vpc-id vpc-095586e614ea1a60a
aws ec2 delete-vpc --vpc-id vpc-038ed6ddc113dfc3f
aws ec2 delete-vpc --vpc-id vpc-0f17184ddbfe50ce2

echo === FINAL CHECK ===
echo Remaining security groups:
aws ec2 describe-security-groups --query "SecurityGroups[*].[GroupName,GroupId]" --output table