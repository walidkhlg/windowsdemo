from publiccloudsdk import Sdk
import time
import os
import json
import argparse
import subprocess


def ami_status_check(aspire,account,ami):
    res = json.loads(sdk.get_application_ami(aspire, account, ami))
    if res['state'] == 'READY':
        print("ami build complete !")
        return True
    print("ami build still in process")
    return False


parser = argparse.ArgumentParser(description="Windows Demo")
parser.add_argument('-a', '--aspire', required=True, help="Application Aspire code")
parser.add_argument('-c', '--account', required=True, help="Account name")
parser.add_argument('-r', '--region', default = "eu-west-1", help="Account name")
args = parser.parse_args()

try:
    sdk = Sdk()
except Exception as ex:
    print("Authentification failed ")
    print(ex)
    exit(1)

trust = [{"name" : "EC2"}]
menu = True
keyname = ""
amiId = ""
ami_id = ""
id_ami ="" ## id in api
app_role_name = ""
key =""
ready=False


# create kms key ######
def create_kms_key():
    while keyname is "":
        keyname = input("Enter a name for the kms key:\n")
    try:
        result = json.loads(sdk.create_encryption_key(args.aspire, args.account, keyname, args.region))
        key = result['id']
        print("Key created : "+key)
    except Exception as ex:
        print("An error occured!")
        print(ex)


# create applicaiton ami
def create_app_ami():
    description = ""
    while ami_id == "" or description == "":
        ami_id = input("id of the ami to encrypt:\n")
        description = input("Enter a description for this ami:\n")
    try:
        result = json.loads(sdk.create_application_ami(args.aspire, args.account, ami_id, key, description))
        amiId = result['amiId']
        id_ami = result['id']
        print("ami build started")
    except Exception as ex:
        print("An error occured!")
        print(ex)

# create application role
def create_app_role():
    while app_role_name is "":
        app_role_name = input("Enter a name for the application role:\n")
    with open('role.json', 'r') as policy_file:
        policies = json.loads(policy_file.read())
    try:
        json.loads(sdk.create_application_awsrole(args.aspire, args.account, app_role_name, 'test create role via sdk',
                                                  args.region, policies, trust))
        print("role created : " + app_role_name)
    except Exception as ex:
        print("An error occured!")
        print(ex)


# deploy stack
def deploy():
    menu = False
    while not ready:
        print("AMI no ready yet, please wait ...")
        time.sleep(60)
        ready = ami_status_check(args.aspire, args.account, id_ami)
    print("***** Deploying stack with the previously created ressources *****")
    os.chdir("..")
    subprocess.call(["terraform", "plan", "-var", "kms_key=" + key, "-var", "instance_role=" + app_role_name, "-var",
                     "launch_ami=" + amiId])
    subprocess.call(["terraform", "apply", "-var", "kms_key=" + key, "-var", "instance_role=" + app_role_name, "-var",
                     "launch_ami=" + amiId, "-auto-approve"])
    elb = subprocess.getoutput('terraform output elb-address')
    name = ""
    while not name.isalpha():
        name = input("Enter a name for the DNS record:\n")
    try:
        sdk.create_dns_record(args.aspire, args.account, name, elb, 'CNAME')
    except Exception as ex:
        print("An error occured while creating DNS!")
        print(ex)
    print("DNS Record created:\nhttp://" + name + "." + args.aspire + ".aws.cloud.airbus.corp")


while menu:
    choice = 0
    print("1- Create KMS Key \n 2- Create application AMI\n 3- Create application Role \n 4- Exit and deploy stack\n")
    while choice not in [1,2,3,4]:
        choice = int(input("Please make a choice :\n"))
    if choice == 1:
        create_kms_key()
    elif choice == 2:
        create_app_ami()
    elif choice == 3:
        create_app_role()
    elif choice == 4:
        deploy()
