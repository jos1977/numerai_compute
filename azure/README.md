
# Numerai Azure Compute

The Azure compute environment contains the following components:
- Azure Container Instance: Compute used for running Docker containers
- Logic App: Business Logic used which starts Docker Containers in ACI, and can be triggered through webhook from Numerai
- API Connector: connector used between ACI and Logic App to handle start commands

![Azure Compute Envirojnmen](https://github.com/jos1977/numerai_compute/blob/main/azure/docs/Azure%20ACI.png "Azure Compute Environment")

## Prerequisites
The following is required to deploy Dockers containers to Docker Hub and run containers in Azure:
- Windows or Linux hardware (laptop)
- Powershell 5.x / 7.x (Powershell ISE)
- Docker Desktop for Windows / Linux (or at least docker commands available)
- A Docker Hub account (can be a free or paid account)
- One Docker Hub private repository for storing Docker container
- Docker should be connected to Docker Hub with an account
- One Azure tenant and subscription, can be a pay-per-use subscription
- One numerai account and model, including credentials.
- Optionally: Visual Studio Code (for development)

## General Information
The Logic App will be triggered through the configured webhook from Numerai (just like with Amazone) and start the Container Instance. After performing prediction and uploading prediction to Numerai the container will automatically terminate to save cost. You can use the example docker python and replace this with your own and build a complete pipeline here. It is also possible to change the maximum memory up until 16gb for ACI (this is the limit). Currently only cpu is supported but you could make the changes yourself in the scripting to support this, ACI can handle GPU. Maybe in the future i will look at VM or VM scale set as an alternative to increase the maximum memory and compute capabilities (costs however will be much bigger ofcourse). The question is if for inference this is actually needed, especially if you only predict live results which should be quick. The example model uses the minimum feature set and all era's, and only required 2.5gb ram for execution which is quite cost effective.


## How to build the Docker Container and push to Docker Hub
- Make sure that the prerequisites are done and that the git repo is cloned locally
- Make any changes you want to the python script used: example_docker.py. This is based on the numerai example version (38 features, small version),this is the one you want to change to include your own versions. This file is stripped and doesnt contain the training part, but an example model.pkl file is included in the repo.
- start the powershell 'BuildPushDocker.ps1"
- when asked fill in the Docker Image location on Docker Hub (example: user/name:latest). 
- the docker image will be build and pushed to Docker Hub.
Note: the assumption is that the docker tools on the local environment eare already connected to Docker Hub. If not please do this first.

## How to Provision Azure Resources and connect Numerai Compute webhook
- Make sure that the prerequisites are done and that the git repo is cloned locally
- start the powershell 'CreateAciEnvironment.ps1'
- IF there is any initial error about execution policies, execute the followng powershell first: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
-  The script will ask for the following details:
   -  "Please enter your Numerai Public Id (XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)"
   -  "Please enter your Numerai Secret Key (XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)"
   -  "Please enter your Numerai Model Id Key (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
   -  "Please enter your Azure subscription id (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
   -  "Please enter the Azure Location (example eastus)"
   -  "Please enter the Azure Resourcegroup Name"
   -  "Please enter the Azure Container Instances Name"
   -  "Please enter the ACI Memory allocation (example: 2.5)"
   -  "Please enter the ACI CPU allocation (example: 1)"
   -  "Please enter the Docker Hub Username"
   -  "Please enter the Docker Hub Password"
-  After filling in the required information azure resources will be deployed.
-  When the script is finished, in the output there will be a https link mentioned, this is the webhook link that you need to fill in in numerai at your model.
-  No go to your Azure environment and open the new Logic App, select Edit
-  Open 'start containeers in your resource group', over here you need to authorize the connection manually since the script cant to this, see screenshots below. Its just a matter of signing in once with your azure credentials and then save the logic app again.

![Logic App Conn1](https://github.com/jos1977/numerai_compute/blob/main/azure/docs/Azure%20Conn.png "Azure App Conn1")
![Logic App Conn2](https://github.com/jos1977/numerai_compute/blob/main/azure/docs/Azure%20Conn%202.png "Logic App Conn2")

## Issues, Contact
If you encounter any problem or have suggestions, feel free to open an issue or contact me at Numerai (orum / rocketchat / dm). My handle at RocketChat is 'QE', my handle in the forum is 'qeintelligence'.


