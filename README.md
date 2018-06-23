# Deploying WordPress on Elastic Beanstalk

## Install the EB CLI

If you are on MacOS, use brew to install the EB CLI.

```Shell
$ brew update
```
```Shell
$ brew install awsebcli
```
```Shell
$ eb --version
```

Alternatively, follow the instructions [here](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html).

## Set up RDS MySQL

Use CloudFormation template in this repository to create a MySQL

        aws cloudformation deploy \
          --stack-name "wordpressdb" \
          --template-file .cloudformation/rds-mysql.yml \
          --parameter-overrides "DBIdentifier=wordpressdb" "DBIdentifier=wordpressdb" "DBPassword=xxxxx" "DBUser=admin" "VpcId=vpc-73be8a17" \
          --capabilities CAPABILITY_NAMED_IAM

## Set up elasticbeanstalk

## Set up your project directory

Download WordPress and push to Github.

        ~$ curl https://wordpress.org/latest.tar.gz -o wordpress.tar.gz

## Create an Elastic Beanstalk environment

1. Configure a local EB CLI repository with the PHP platform.

        ~/wordpress-test$ eb init
        Follow the command line instructions to finish configurations.

2. Create an Elastic Beanstalk environment with PHP platform.

        ~/wordpress-beanstalk$ eb create
        Enter Environment Name
        (default is wordpress-test-dev): wordpress-test
        Enter DNS CNAME prefix
        (default is wordpress-test):

        Select a load balancer type
        1) classic
        2) application
        3) network
        (default is 1): 2
        Creating application version archive "app-7e2a-180623_114601".
        Uploading: [##################################################] 100% Done...
        ...

        ~/wordpress-beanstalk$ eb create -s  
        Add -s if you only want to set up a single wordpress instance without any load balancer and auto scaling

## Deploy WordPress to your environment
Deploy the project code to your Elastic Beanstalk environment.

First, confirm that your environment is `Ready` with `eb status`.

```Shell
~/wordpress-beanstalk$ eb status
~/wordpress-beanstalk$ eb deploy
```

### NOTE: security configuration

This project includes a configuration file (`loadbalancer-sg.config`) that creates a security group and assigns it to the environment's load balancer, using the IP address that you configured in `ssh.config` to restrict HTTP access on port 80 to connections from your network. Otherwise, an outside party could potentially connect to your site before you have installed WordPress and configured your admin account.

You can [view the related SGs in the EC2 console](https://console.aws.amazon.com/ec2/v2/home#SecurityGroups:search=wordpress-beanstalk).

# Updating keys and salts

The WordPress configuration file `wp-config.php` also reads values for keys and salts from environment properties.

Use `eb setenv` to set these properties directly on the environment.

    DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, ...

```Shell
~/wordpress-beanstalk$ eb setenv DB_HOST=localhost DB_NAME=wordpressdb  ...
...
```

Manually scale up to run the site on multiple instances for high availability.
```Shell
~/wordpress-beanstalk$ eb scale 3
```
#Off Load wp-content

When deploying using eb deploy, it has a limitation on the size of the zip file. If there are too many files under wp-content folder, it is better to store files in storage like AWS S3 or install plugin to server wp-content from other storage.

    Add `.ebextensions/01_s3_sync.config` and fill it with below configurations
    files:
      "/opt/elasticbeanstalk/hooks/appdeploy/post/01_sync_images_file.sh":
        mode: "000755"
        owner: root
        group: root
        content: |
          #!/usr/bin/env bash
          aws s3 sync s3://eatigo-blog-images /var/www/html/wp-content/uploads --delete
          sudo chown -R webapp:webapp /var/www/html/wp-content

    It will put a post-deploy script on the instance and pull the files after the wordpress application deployed. If this script is ran before deployment, the pulled content will be override by deployment package, which not contain the wp-content files.

    Make sure the instance profile has correct permission to run aws cli in this scripts.
