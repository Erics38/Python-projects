@echo off
echo === DELETING NAT GATEWAYS ===
echo This will delete NAT Gateways and their network interfaces

aws ec2 delete-nat-gateway --nat-gateway-id nat-0af6fe4907a7f31cf
aws ec2 delete-nat-gateway --nat-gateway-id nat-03b93db953de4f0e8
aws ec2 delete-nat-gateway --nat-gateway-id nat-0267cb20c2794d782
aws ec2 delete-nat-gateway --nat-gateway-id nat-0ede4e95cd65f8c2f

echo NAT Gateways deletion initiated...
echo Network interfaces will be automatically deleted
echo Wait 5-10 minutes before deleting VPCs