from publiccloudsdk import Sdk
import json
import argparse
import subprocess

parser = argparse.ArgumentParser(description="Windows Demo")
parser.add_argument('-a', '--aspire', required=True, help="Application Aspire code")
parser.add_argument('-c', '--account', required=True, help="Account name")
parser.add_argument('-r', '--region', default = "eu-west-1", help="Account name")
args = parser.parse_args()

sdk = Sdk()

# create kms key ######
keyname = ""
while keyname is "":
    keyname = input("Enter a name for the kms key:\n")

result = json.loads(sdk.create_encryption_key(args.aspire, args.account, keyname, args.region))
key = result['id']
print(key)

# create encrypted applicaiton AMI
base_ami_id = ""
while base_ami_id is "":
    base_ami_id = input("Enter the id of the AMI to encrypt")
    sdk.create_application_ami(args.aspire, args.account, key, 'Test AMI encryption')

app_role_name = ""
while app_role_name is "":
    app_role_name = input("Enter a name for the application role:\n")
with open('role.json','r') as policy_file:
    policies = policy_file.read()


result = json.loads(sdk.create_application_awsrole(args.aspire, args.account,app_role_name , 'test create role via sdk', args.region, policies))
role_arn = result['arn']

#subprocess.call(["terraform", "plan", "-var", "kms_key="+key, "-var", "instance_role="+role_arn, "-var", "launch_ami="+])
