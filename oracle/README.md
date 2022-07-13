
# Oracle Compute
This repository contains the numerai compute example in combination with Oracle Cloud provider. The examples here are meant to be used for inferencing (predictions). The Oracle Compute version is based on the free tier and as such doesn't incur any cost. There are two compute engines available, armx64 (ampere a1) with 24Gb ram and AMD x86/x64 with 1GB ram. The following example will be based on AMD but could also potentially work for the Ampere version (depending on library requirements).

## Disclaimer
No guarantees are given that the example code and instructions here are 100% correct, and make sure to keep check of your cloud costs, it is quite esasy with some little mistakes to increase costs considerably!.As such, if these examples are used, you use them at your own risk! :-)

## Installation steps
For now the installation steps are manual and require knowledge about server maintenance, ssh/sftp and basic linux (ubuntu knowledge). Perform the following steps to create the Ubuntu server and get the server configured for daily/weekly predictions at numerai.

### Create an Oracle Free Tier Account and Compute Engine
The cloud provider used is Oracle Infrastructure which also a free tier and is in principle sufficient for any basic numerai model (regression/tf).
The link to the free tier is: https://www.oracle.com/nl/cloud/free/#always-free

Follow the installation steps in the link below, with the following exceptions:

- Have an ubuntu 20.0 instead of 18.0
- The monitoring installation is optional, I didnt do that
- Make sure the user is 'ubuntu', although I think this is by default

https://virtualizationreview.com/articles/2021/09/14/using-oracle-cloud.aspx

Just make sure you have the login credentials (private key), you need this in the following steps.

### Configure the Ubuntu Compute Engine
Now login again with SSH, I usually use Putty for this, you can also easily configure the private key for access with this tool

In order to have some more memory available, we can use swap file in Ubuntu. This will ofcourse mean a degraded performance, however for a prediction this is a lower priority (except if you have really beefy stuff happening in your pipeline). Follow steps 1 till 5 in the following tutorial, change the example from 1Gb to something like 12Gb (this is what I used for the medium feature set) : 

https://linuxize.com/post/create-a-linux-swap-file/


### install Anaconda, virtualenv environments
Follow installation steps 1 till 4 in the following link:

https://phoenixnap.com/kb/how-to-install-anaconda-ubuntu-18-04-or-20-04

After this create at least a virtual environment 'numerai' and any other you need. For the 'numerai' env, do a pip install of the numerai_requirements.txt in the repo. 

### Configure and Upload Numerai python scripts
Now configure the example ipynb / python scrips in the repository, most likely you need to do at least this;
- Fill in the numerai keys/secrets
- Add your own models instead of the example model
- Any preprocessing/postprocessing steps you have or any library integrations (eg numerblox,...)

The following step is to upload all files (from this level and all subfolders) to the following folder on the compute: /home/ubuntu/numerai/
My preferred tool for this is WinSCP, but any tool that supports authentication by keys will work.

After uploading, SSH login to the compute, go to the numerai folder and convert all ipynb files to py files with the following command:

jupytext --to py v2_load.ipynb

Do this for all ipynb files.

### Configure CronJob
Add a cronjob for executing the /home/ununtu/numerai/orchestration_predict.py file in the weekends (I would say start time saturday 23.00 UTC and maybe once more on sunday for example for the weekly predictions). The orchestration file will trigger all the live prediction loadings steps and prediction/uploading.
Follow the instructions at the following link to set it up:

https://serverspace.io/support/help/automate-tasks-with-cron-ubuntu-20-04/

Thats it! you now have a working compute engine running for free!


## Issues, Contact
If you encounter any problem or have suggestions, feel free to open an issue or contact me at Numerai (orum / rocketchat / dm). My handle at RocketChat is 'QE', my handle in the forum is 'qeintelligence'.


