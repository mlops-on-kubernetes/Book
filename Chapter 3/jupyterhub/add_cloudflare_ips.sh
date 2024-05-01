# first we download the list of IP ranges from CloudFlare
wget https://www.cloudflare.com/ips-v4

# set the security group ID
SG_ID="sg-0a35cafb7a77fef4e"

# iterate over the IP ranges in the downloaded file
# and allow access to ports 80 and 443
while read p
do
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --ip-permissions IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges="[{CidrIp=$p,Description='Cloudflare'}]"
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --ip-permissions IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges="[{CidrIp=$p,Description='Cloudflare'}]"
done< ips-v4

rm ips-v4
