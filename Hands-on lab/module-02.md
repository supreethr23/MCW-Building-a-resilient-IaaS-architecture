# Exercise 2: Enable Disaster Recovery for the Contoso application

### Estimated Duration: 60 minutes

In this exercise, you will enable a secondary DR site. This site will support each tier of the Contoso application, using a different technology in each case. The DR approach is summarized in the following table.

### Objectives
In this exercise, you will complete the following tasks:
   - Task 1: Deploy DR resources.
   - Task 2: Inspect DR for the Domain Controller tier.
   - Task 3: Configure DR for the SQL Server tier.
   - Task 4: Configure DR for the Web tier.
   - Task 5: Configure a public endpoint using Azure Front Door.

### Task 1: Deploy DR resources

In this task, you will deploy the resources used by the DR environment. First, you will deploy a template which will create the network and virtual machines. You will then manually deploy the Recovery Services Vault and Azure Automation account used by Azure Site Recovery.

1. In the Azure portal, navigate to Cloudshell as shown below and choose Powershell.

    ![Screenshot of the Azure Cloud Shell with URL and PowerShell mode highlighted.](images1/build1.png "Azure Cloud Shell")

1. In the getting started page, select **Mount storage account** (1) and choose the **Subscription** (2) and select **Apply**(3).

   ![Screenshot of the Storage account storage.](images1/cloudshellstrg1.png "Azure Cloud Shell")

1. In the Mount storage account page, select **We will create a storage account for you** (1) and select **Next**(2).

   ![Screenshot of the Storage account storage.](images1/cloudshellstrg2.png "Azure Cloud Shell")

1. Update the **-Location** parameter in each command below to specify a secondary location different from **ContosoRG1**. Then, execute the commands to create the disaster recovery (DR) resource group and deploy the DR resources. 
  The deployment can take upto 20 minutes to complete.

   ```powershell
   New-AzResourceGroup -Name 'ContosoRG2' -Location '<Enter the location>'
   New-AzSubscriptionDeployment -Name 'Contoso-IaaS-DR' -TemplateUri 'https://raw.githubusercontent.com/CloudLabs-MCW/MCW-Building-a-resilient-IaaS-architecture/prod/Hands-on%20lab/Resources/templates/contoso-iaas-dr.json' -Location '<Enter the location>'
   ```

   > **Note:** If your deployment fails with an error *`"The requested size for resource '<resourceID>' is currently not available"`*, add the parameter `-skuSizeVM 'D2s_v5'` to the end of the `New-AzSubscriptionDeployment` and run the command again:

   ```powershell
    # Only run this command if the previous deployment failed with a error that size was not available
    New-AzSubscriptionDeployment -Name 'Contoso-IaaS-DR-SKU' `
        -TemplateUri 'https://raw.githubusercontent.com/CloudLabs-MCW/MCW-Building-a-resilient-IaaS-architecture/prod/Hands-on%20lab/Resources/templates/contoso-iaas-dr.json' `
    -Location '<Enter the location>' -skuSizeVM 'D2s_v5'
    ```

1.  Take a few minutes to review the template while it deploys. To review the template and deployment progress, navigate to the Azure portal home page, select **Resource Groups**, then **ContosoRG2** and**Deployments**. Note that the template includes:
    -  A DR virtual network, which is connected using VNet peering to the existing virtual network
    -  Two additional domain controller VMs, **ADVM3** and **ADVM4**
    -  An additional SQL Server VM, **SQLVM3**
    -  Azure Bastion, to enable VM access

    ![Screenshot of the disaster recovery resources for the Web application.](images1/E2T1S3.png "Successful deployment of Web DR resources")

1. Now, you will create the Recovery Services Vault used to replicate the Web tier VMs and orchestrate the cross-site failover. From the Azure portal, search for **Recovery Services Vault** and then search for and select it.

    ![](images/E3T1S1upd.png)

1. In the **Recovery Services Vault** page click on **Create**.

    ![Screenshot of the Backup and Site Recovery Screen with the Create button selected.](images/recoveryselect.png "Backup and Site Recovery Screen Create Button")

1.  Complete the **Recovery Services Vault** blade using the following inputs, then select **Review and Create**, followed by **Create**:

    - **Resource Group**: **ContosoRG2**
    - **Name**: **BCDRRSV<inject key="DeploymentID" />**
    - **Location**: your **secondary region** that you choose in step 2

    ![Screenshot of the Backup and Site Recovery Screen with the Create button selected.](images/recoveryimg.png "Backup and Site Recovery Screen Create Button")

1.  Once the **BCDRRSV<inject key="DeploymentID" enableCopy="false"/>** Recovery Service Vault has been created, open it in the Azure portal and select the **Site Recovery** tab.

    ![Screenshot of the Backup / Site Recovery tabs with Site Recovery tab selected.](images1/ex2-task1-step6.png "Backup / Site Recovery tabs")

1. This is your dashboard for Azure Site Recovery (ASR).

    ![The Azure Site Recovery dashboard displays.](images1/ex2-task1-step7.png "Azure Site Recovery dashboard")

   > **Important:** Next, you will set up the Azure Automation account that will be used to automate certain failover and fail-back tasks. This will require several PowerShell scripts to be imported as Azure Automation runbooks. **Be sure to execute the following steps from the LabVM, since that is where the scripts are located.**

1.  From the Azure portal, search for and select **Automation**.
   
   ![Screenshot of the Backup / Site Recovery tabs with Site Recovery tab selected.](images1/build3.1.png "Backup / Site Recovery tabs")

1.  Complete the **Add Automation Account** blade using the following inputs and then select **Create** (4):

    - **subscription**: Select the default subscription
    - **Resource group**: Use existing / **ContosoRG2** (1)
    - **Name**: BCDR<inject key="DeploymentID" /> (2).
    - **Location**: your secondary region that you choose in step 2 (3)
    

    ![Fields in the Add Automation Account blade are set to the previously defined values.](images/updated111.png "Add Automation Account blade")

    > **Note:** Azure Automation accounts are only allowed to be created in certain Azure regions, but they can act on any region in Azure (except Government, China or Germany). It is not a requirement to have your Azure Automation account in the same region as the failover resources, but it **CANNOT** be in your primary region.

1. In the **Azure Automation Account** blade and select **Runbooks (1)**, then select **Import a runbook (1)**.

    ![The 'Import a runbook' button is highlighted in Azure Automation.](images1/E2T1S10upd1.png "Import a runbook button")

    
1. Select the **Folder** icon on the Import blade and select the file **ASRRunbookSQL.ps1** from the `C:\HOL\` directory on the **LABVM**. The Runbook type should default to **PowerShell Workflow**. Change the name of the Workflow inside of the Runbook script to **ASRSQLFailover**. Select **Import**.

    ![Fields in the 'Import a runbook' blade are set to the previously defined values.](images/Ex2-t1-step15.png "Import a runbook")

1. Once the Runbook is imported, the runbook editor will load. If you wish, you can review the comments to better understand the runbook. Once you are ready, select **Publish**, followed by **Yes** at the confirmation prompt. This makes the runbook available for use.

    ![On the top menu of the Edit PowerShell Workflow Runbook blade, Publish is selected.](images1/E2T1S12.png "Publish runbook")

1. Repeat the above steps to import and publish the **ASRRunbookWEB.ps1** runbook and change the name of the Workflow inside the Runbook script to **ASRWEBFailover**

1. Navigate back to **Runbooks**, and make sure that both Runbooks show as **Published**.

    ![Two runbooks have authoring status as published: ASRSQLFailover, and ASRWEBFailover.](images/updated12.png "Runbooks")

   >**Note:** If the status of the runbook doesnt show as published, kindly import the runbooks and and publish it again.

   > **Note:** When you configure the ASR Recovery Plan for the IaaS deployment you will use the SQL Runbook as a Pre-Failover Action and the Web Runbook as a Post-Failover action. They will run both ways and have been written to take the "Direction", of the failover into account when running.

1. Next, you will create a variable in Azure Automation which contains settings (such as resource group names and VM names) which describe your environment. This information is required by the runbooks you imported. Using variables allows you to avoid hard-coding this information in the runbooks themselves.

1. In your Azure Automation account, select **Variables**, then **Add a variable**.

    ![Azure portal showing variables pane in Azure Automation.](images1/E2T1S15upd.png "Add a variable")

1. In the **New Variable** blade, enter `BCDRIaaSPlan` as the variable name. The variable type should be **String**. Paste the following into the variable **Value**, then select **Create**.

    ```json
    {
        "PrimarySiteRG": "ContosoRG1",
        "PrimarySiteSQLVM1Name": "SQLVM1",
        "PrimarySiteSQLVM2Name": "SQLVM2",
        "PrimarySiteSQLPath": "SQLSERVER:\\Sql\\SQLVM1\\DEFAULT\\AvailabilityGroups\\BCDRAOG",
        "PrimarySiteVNetName": "VNet1",
        "PrimarySiteWebSubnetName": "Apps",
        "PrimarySiteWebLBName": "ContosoWebLBPrimary",
        "SecondarySiteRG": "ContosoRG2",
        "SecondarySiteSQLVMName": "SQLVM3",
        "SecondarySiteSQLPath": "SQLSERVER:\\Sql\\SQLVM3\\DEFAULT\\AvailabilityGroups\\BCDRAOG",
        "SecondarySiteVNetName": "VNet2",
        "SecondarySiteWebSubnetName": "Apps",
        "SecondarySiteWebLBName": "ContosoWebLBSecondary"
    }
    ```

    ![The 'New Variable' blade is filled in with the variable name and value.](images1/E2T1S16upd.png "New Variable")

1. Notice that the variable **BCDRIaaSPlan** has been created. 

    ![The 'BCDRIaaSPlan' variable is shown in the Automation Account.](images1/E2T1S16upd1.png "Automation Account variables")

1. Before continuing, check that the template deployment you started at the beginning of this task has been completed. From the Azure portal home page, select **Subscriptions**, select your subscription, then select **Deployments**. 

    ![The 'Contoso-IaaS-DR' template deployment shows as successful.](images1/E2T1S18upd.png "Template status")

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   > - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task. 
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help
   <validation step="1134d3fd-1557-47f5-89db-4b6eebd50650" />

### Task 2: Inspect DR for the Domain Controller tier

In this task, you will simply review the rest of the configuration to confirm everything is as it should be.

The failover site in has been deployed with two additional domain controllers, **ADVM3** and **ADVM4**. These are integrated with the existing `contoso.com` domain hosted on **ADVM1** and **ADVM2** in the primary site. They run in a fully active-active configuration (there is therefore no failover required for this tier).The configuration of these domain controllers is fully automatic. 

1.  From the Azure portal home page, select **Subscriptions**, choose your subscription, and select **Deployments**, then open the **Contoso-IaaS-DR** deployment used for the DR site.

    ![Click path to the 'Contoso-IaaS-DR' deployment.](images1/E2T2S1upd.png "DR deployment")

1.  Select **Template** and review the template contents. Note the use of `dependsOn` to carefully control the deployment sequence. The resources are deployed as follows:

    - The VNet2 virtual network is created
    - VNet2 is peered with VNet1. This creates connectivity between the two networks
    - The DNS settings in VNet2 are updated to point to the domain controllers in VNet1
    - The new domain controllers, **ADVM3** and **ADVM4** are deployed to VNet2, with static private IP addresses. A custom script extension is used to configure these VMs as domain controllers.
    - The DNS settings in VNet2 are then updated to point to these new domain controllers.
    - Other VMs (such as **SQLVM3**) are now able to be deployed

    ![Azure portal showing the Contoso-IaaS-DR template, with the deployment sequence highlighted.](images1/E2T2S2.png "DR template")

1.  Navigate to the **ContosoRG2** resource group. Click on network interface (NIC) **ADVM3NIC** resources for the ADVM3 and ADVM4 VMs to confirm their network settings include the static private IP addresses 10.1.3.100 and 10.1.3.101, respectively. On the left hand side Under Settings click on **IP configurations**         and then select ipconfig1 and also change the assignment as **Static** and also update the ip address.

    ![Network interface configuration showing a static private IP address for ADVM3.](images1/ipconfig.png "Static IPs")

1.  Navigate to the **VNet2** virtual network. Select **DNS servers** and confirm that the IP addresses for **ADVM3** and **ADVM4** are configured.

    ![The Azure portal shows the DNS settings for VNet2.](images1/E2T2S4.png "Template status")

1.  Select **Peerings** and confirm that the network is peered with VNet1.

    ![The Azure portal shows VNet2 is peered with VNet1.](images1/E2T2S5.png "VNet peering")


### Task 3: Configure DR for the SQL Server tier

In this task, you will extend the SQL Server Always On Availability Group you created earlier to include **SQLVM3** as an asynchronous replica running in the DR site.

1. In the Azure portal  open a Azure Bastion session to **SQLVM3** virtual machine which is present in ContosoRG2 resource group. Use `demouser` as the username and use **Password**: `Demo!pass123`

1. Launch SQL Server Management Studio, a new dialog box will open, ensure that **Trust server certificate** is selected and click on **Connect** to sign on to **SQLVM3**. 

    > **Note**: The username for your lab should show **SQLVM3\demouser**.

    ![Screenshot of the Connect to Server dialog box.](images1/E3T3S27upd1.png "Connect to Server dialog box")
    
1. And then expand **Security** and then **Logins**. You'll notice that only `SQLVM3\demouser` is listed.

    ![In SQL Server management studio, SQLVM2 is expanded, then Security is expanded, then Login is expanded. Only the SQLVM2\demouser account is seen.](images1/E2T3S28upd1.png)

1. Right-click on **Logins** and then select **New Login...**

    ![The dialog box from the right-click on Logins is shown with an option to select New Login.](images1/E1T3S29upd.png)

1. In **Login name:** type **contoso\demouser**, then select **Server Roles**.

    ![The Login-New dialog box is displayed. In the Login name: box, the username contoso\demouser has been typed in. From here, it shows you selected the Server Roles tab in the left side navigation.](images1/E1T3S30.png)

1. Check the box for **sysadmin** and select **OK**.

    ![The Server Roles tab is shown in the Login - New dialog box. In this dialog box, public remains checked, and a check is added to the sysadmin option.](images1/E1T3S31.png)

1. Return to the Azure portal and navigate to the **ContosoSQLLBSecondary** load balancer blade in **ContosoRG2**. Select **Backend pools** and open **BackEndPool1**. Note that the pool is connected to the **VNet2** virtual network. Select **+ Add**.

   ![Azure portal showing where to select Add on the ContosoSQLLBSecondary load balancer backend pool to add a new VM.](images/EX2-T3-S1.png "Backend pool")

1. Select **SQLVM3**. Select **Add**.  Select **Save** on **BackEndPool1** to save changes.

     ![Azure portal showing SQLVM3 being added to the ContosoSQLLBSecondary load balancer backend pool.](images1/E2T3S2.png "SQL VM added to backend pool")

   >**Note:** For this lab, the DR site is configured with a single SQL Server VM. Using a load balancer is therefore not strictly required. However, it allows the DR site to be extended to include its own HA cluster if required.

1. Return to your browser tab containing your Bastion session with **SQLVM1**. (If you have closed the tab, reconnect using Azure Bastion with username `demouser@contoso.com` and password `Demo!pass123`.)

1.  On **SQLVM1**, use **Windows PowerShell ISE** to execute the following command. This will add **SQLVM3** as a node in the existing Windows Server Failover Cluster.

    ```PowerShell
    Add-ClusterNode -Name SQLVM3
    ```

1.  Select **Start** and then **Windows Administrative Tools**. Locate and open the **Failover Cluster Manager**. Expand the **AOGCLUSTER** and select **Nodes**. Note that SQLVM3 is now included in the list, with status **Up**.

    ![In Failover Cluster Manager, Nodes is selected in the tree view, and three nodes display in the details pane.](images/dr-fcm-3nodes.png "Failover Cluster Manager")

1.  Return to the Azure portal. Locate **SQLVM3**, and connect to the VM using Azure Bastion with username `demouser@contoso.com` and password `Demo!pass123`.

1.  On **SQLVM3**, select **Start** and launch **SQL Server 2017 Configuration Manager**.

    ![Screenshot of the SQL Server 2017 Configuration Manager option on the Start menu.](images/image166upd.png "SQL Server 2017 Configuration Manager option")

1.  Select **SQL Server Services**, then right-click **SQL Server (MSSQLSERVER)** and select **Properties**.

    ![In SQL Server 2017 Configuration Manager, in the left pane, SQL Server Services is selected. In the right pane, SQL Server (MSSQLSERVER) is selected, and from its right-click menu, Properties is selected.](images/image167upd.png "SQL Server 2017 Configuration Manager")

1.  Select the **AlwaysOn High Availability** tab and check the box for **Enable AlwaysOn Availability Groups**. Select **Apply** and then select **OK** on the message that notifies you that changes won't take effect until after the server is restarted.

    ![In the SQL Server Properties dialog box, on the AlwaysOn High Availability tab, the Enable AlwaysOn Availability Groups checkbox is checked and the Apply button is selected.](images/image168.png "SQL Server Properties dialog box")

    ![A pop-up warns that any changes made will not take effect until the service stops and restarts. The OK button is selected.](images/image169.png "Warning pop-up")

1. On the **Log On** tab, change the service account to `contoso\demouser` with the password `Demo!pass123`. Select **OK** to accept the changes, and then select **Yes** to confirm the restart of the server.

    ![In the SQL Server Properties dialog box, on the Log On tab, fields are set to the previously defined settings. The OK button is selected.](images1/E2T3S10.png "SQL Server Properties dialog box")

    ![A pop-up asks you to confirm that you want to make the changes and restart the service. The Yes button is selected.](images/image171.png "Confirm Account Change pop-up")
    
1. Return to your session with **SQLVM1**. Open **Microsoft SQL Server Management Studio 20** and connect to the local instance of SQL Server.

1. Expand the **Always On High Availability** node. Under **Availability Group Listeners**, right-click on **BCDRAOG** and select **Properties**.

    ![On the BCDRAOG Listener context menu, 'Properties' is selected.](images1/E2T3S12.png "Listener properties")

1. On the BCDRAOG Listener properties dialog, select **Add**.

    ![On the BCDRAOG Listener properties dialog, 'Add' is selected.](images1/E2T3S13.png "Listener - Add")

1. On the Add IP Address dialog, check the subnet is **10.1.2.0** (this is the Data subnet in VNet2). Enter the IP address **10.1.2.100** (this is the frontend IP of the SQL load balancer in VNet2). Select **OK**.

    ![On the BCDRAOG Listener Add IP Address dialog, the IP address is entered as specified.](images1/E2T3S14.png "Listener - IP")

1. On the BCDRAOG Listener properties dialog, two IP addresses should now be shown. Select **OK** to close the dialog and commit the change.

    ![On the BCDRAOG Listener properties dialog, two IP addresses are shown. 'OK' is selected.](images1/E2T3S15.png "Listener - two IPs")

1. Under **Availability Groups**, right-click on **BCDRAOG (Primary)** and select **Add Replica..** to open the Add Replica wizard.

    ![In Object Explorer, under Always On High Availability the BCDRAOG availability group is selected, and from its right-click menu, Add Replica is selected.](images1/E2T3S16upd.png "SQL Server Management Studio - Add Replica")

1. Select **Next** on the Wizard.

    ![On the Add Replica Wizard 'Introduction' page, Next is selected.](images1/E2T3S17.png "Add Replica wizard")

1. Select **Connect** to connect to SQLVM2, then **Connect** again on the 'Connect to Server' prompt. Then select **Next**.

    ![On the Add Replica Wizard 'Connect to Replicas' page, SQLVM2 is connected and Next is selected.](images1/E2T3S18.png "Connect to Replicas page")

1. On the **Specify Replicas** page, select **Add Replica...**.

    ![Screenshot of the Add replica button.](images1/E2T3S19.png "Add replica button")

1. On the **Connect to Server** dialog box enter the Server Name of **SQLVM3** and select **Connect**.

    ![Screenshot of the Connect to Server dialog box.](images1/E3T3S27upd1.png "Connect to Server dialog box")

1. For **SQLVM3**, leave the default settings of 'Asynchronous commit' with 'Automatic Failover' disabled. Select **Next**.

    ![The SQLVM3 replica settings are asynchronous commit with automatic failover disabled. The Next button is highlighted.](images1/E2T3S21.png "SQLVM3 replica settings")

1. On the **Select Data Synchronization** page, make sure that **Automatic seeding** is selected and select **Next**.

    ![On the Select Data Synchronization page, the radio button for Automatic seeding is selected. The Next button is selected at the bottom of the form.](images1/E2T3S22.png "Select Data Synchronization page")

1. On the **Validation** screen, you should see all green, except for a warning for 'Checking the listener configuration'. This will be addressed later. Select **Next**.

    ![The Validation screen displays a list of everything it is checking, and the results for each, which all display success except the last one. The Next button is selected.](images1/E2T3S23.png "Validation screen")

1. On the Summary page select **Finish**.

    ![On the Summary page, the Finish button is selected.](images1/E2T3S241.png "Summary page")

1. Once the AOG is built, check each task was successful and select **Close**.

    ![On the Results page, a message says the wizard has completed successfully, and results for all steps is success. The Close button is selected.](images1/E2T3S25.png "Results page")

1. Under Availability Groups, right-click **BCDRAOG (Primary)** and then select **Show Dashboard**. You should see that the **SQLVM3** node has been added and is synchronizing.

    ![Screenshot of the BCDRAOG Dashboard showing SQLVM3 synchronizing.](images1/E2T3S26upd.png "BCDRAOG Dashboard")

1. Move back to **PowerShell ISE** on **SQLVM1**. Open a new file, paste in the following script, and select the **Play** button. This will update the Failover cluster with the new Listener IP address that you created.

    ```Powershell
    $ClusterNetworkName = "Cluster Network 2"
    $IPResourceName = "BCDRAOG_10.1.2.100"
    $ILBIP = "10.1.2.100"
    Import-Module FailoverClusters
    Get-ClusterResource $IPResourceName | Set-ClusterParameter -Multiple @{"Address"="$ILBIP";"ProbePort"="59999";"SubnetMask"="255.255.255.255";"Network"="$ClusterNetworkName";"EnableDhcp"=0}
    Stop-ClusterResource -Name $IPResourceName
    Start-ClusterResource -Name "BCDRAOG"
    ```

    ![In the Windows PowerShell ISE window, the play button is selected. The script from the lab guide has been executed.](images1/E2T3S271.png "Windows PowerShell ISE window")

1. Move back to Failover Cluster Manager on **SQLVM1**, and select **Roles (1)**, then **BCDRAOG (2)**.  Notice how the **Resources (3)** tab shows that the new IP address **10.1.2.100** has been added, and is currently Offline.

    ![In the Failover Cluster Manager tree view, Roles is selected. Under Roles, BCDRAOG is selected, and details of the role display.](images1/E2T3S281.png "Failover Cluster Manager")


### Task 4: Configure DR for the Web tier

In this task, you will configure DR for the Contoso application web tier.

The DR solution for the web tier uses Azure Site Recovery to continually replicate the primary site web tier VMs to Azure storage. During failover, the replicated data is used to create new VMs in the DR site, which is pre-configured with the virtual network and web tier load balancer.

Custom scripts in Azure Automation are called by Azure Site recovery to add the recovered web VMs to the load balancer, and failover the SQL Server.

1. From the Azure portal on **LABVM**, open the **BCDRRSV<inject key="DeploymentID" enableCopy="false"/>** Recovery Services Vault located in the **ContosoRG2** resource group.

1. Under **Getting Started**, select **Site Recovery**.  Next, select **Step 1: Enable replication** in the **For On-Premises Machines and Azure VMs** section. 

    ![In the ASR blade, Getting Started is highlighted. Under For On-Premises Machines and Azure VMs, Step 1: Enable replication is selected.](images/dr-asr-1upd.png "Step 1 selected")

1. On **Step 1 - Source** select the following inputs and then select **Next (5)**:

    - **Location**: **<inject key="Region" enableCopy="false" />** (Primary region)(1).
    - **Resource group**: ContosoRG1 (2).
    - **Virtual machine deployment model**: Resource Manager (3).
    - **Disaster Recovery between Availability Zones?**: No (this option is for DR between availability zones *within* a region) (4).

    ![In the Source blade, fields are set to the previously defined settings.](images/EX2-T4-S31.png "Source blade")

1. On **Step 2 - Virtual Machines**, select **WebVM1** and **WebVM2** and then select **Next**.

    ![In the Select virtual machines blade, the check boxes for WebVM1 and WebVM2 are selected.](images/EX2-T4-S4.png "Select virtual machines blade")

1. On the **step 3 - Replication settings** tab, select the following inputs and then select **Next (4)**  
   - **Target location**: *Select the Secondary region which you had selected previously* (1).
   - **Target resource group**: ContosoRG2 (2).
   - **Failover virtual network**: VNet2 (3).

    ![In the Customize target settings blade, the Target location is set to East US 2 and the customize button highlighted](images/EX2-T5-S3.png "Configure settings blade")

1.  On the **step 4 - Manage** tab, select the following inputs and then select **Next (3)**.

    - **Update settings**: Allow ASR to manage (1) .
    - **Automation Account**: use your existing Automation Account (2).
    
    ![The Replication Policy settings use default values.](images/EX2-T4-ns31.png "Replication policy")

1. On the **step 5 - Review** tab, select **Enable replication**.

    ![Screenshot of the Enable replication button.](images/EX2-T3-S9.png "Enable replication button")

1. The Azure portal will start the deployment. This will take approximately 10 minutes to complete. Wait for replication to complete before moving to the next step.

    ![A message is displayed indicating Enabling replication for two vm(s) has successfully completed.](images/image234.png "Enabling replication for two vm(s)")

    > **Note:** If the replication status indicates failure, monitor the jobs. If all jobs are successful, you can move on to the next step.
    >  ![A message is displayed indicating replication failure.](images/failurerep.png "Enabling replication for two vm(s)")

1. The **BCDRRSV<inject key="DeploymentID" enableCopy="false"/>** blade should still have the **Site Recovery (1)** option (under 'Getting started') selected. Select **Step 2: Manage Recovery Plans (2)**.

    ![Click path to Manage Recovery Plans.](images/dr-asr-8.png "Manage Recovery Plans")

1. Select **+Recovery plan**.

    ![On the Recovery Services vault blade top menu, Add a recovery plan is selected.](images1/E2T4S10upd.png "Add recovery plan")

1. Fill in the **Create recovery plan** blade as follows:

    - **Name**: BCDRIaaSPlan (1).
    - **Source**: **<inject key="Region" enableCopy="false" />** *(This is your primary region)* (2).
    - **Target**: *Secondary region that you had selected* (3).
    - **Allow items with deployment model**: Resource Manager (4).
    - **Select Items**: Select **WebVM1** and **WebVM2**.

        ![Fields in the Create recovery plan blade are set to the previously defined settings.](images1/E2T4S111.png "Create recovery plan blade")

    > **Note:** It is **critical** to use the correct recovery plan name `BCDRIaaSPlan`. This must match the name of the Azure Automation variable you created in the first task in this exercise.

1. Select **OK** to create the recovery plan. After a moment, the **BCDRIaaSPlan** Recovery plan will appear. Select it to review.

    ![In the Recovery Plans blade, BCDRIaaSPlan is selected.](images1/E2T4S12.png "Recovery plans")

1. When the **BCDRIaaSPlan** loads **notice** that it shows **2 VMs in the Source** which is your **Primary** Site.

    You will now customize the recovery plan to trigger the SQL failover and configure the web tier load-balancer during the failover process, select **Customize**.

    ![On the BCDSRV blade top menu, Customize is selected. Under Items in recovery plan, the source shows two and the VM icon.](images1/E2T4S131.png "BCDSRV blade")

1. Once the **BCDRIaaSPlan** blade loads, select the **ellipsis (2)** next to **All groups failover (1)**, then select **Add pre-action (3)** from the context menu.

    ![In the Recovery plan blade, the right-click menu for All groups failover displays and Add pre-action is selected.](images1/E2T4S141.png "Recovery plan blade")

1. On the **Insert action** blade, select **Script** and then provide the name **ASRSQLFailover (1)**. Ensure that your **Azure Automation account (2)** is selected and then choose the Runbook name: **ASRSQLFailover (3)**. Select **OK (4)**.

    ![Fields in the Insert action blade are set to the ASRRunBookSQL script.](images/Ex-2-t3-step171.png "Insert action blade")

    > **Note:** As noted on the 'Insert action' blade, the ASRSQLFailover runbook will be executed on both failover and failback. The runbook has been written to support both scenarios.
    > 
    > **Note:** If the **OK** button does not respond, click the cross icon in the top-right corner, then click **Ok** in the dialog box. And verify in the **BCDRIaaSPlan** blade if the pre-action is coming up.
    > ![issueimage.](images1/cancelbutton.png "Recovery plan blade")

1. Once the **BCDRIaaSPlan** blade loads, select the **ellipsis** next to **Group 1: Start**, then select **Add post action** from the context menu.

    ![In the Recovery plan blade, the Group 1: Start right-click menu displays, and Add post action is selected.](images1/E2T4S16.png "Recovery plan blade")

1. On the **Insert action** blade, select **Script** and then provide the name: **ASRWEBFailover(1)** Ensure that your **Azure Automation account(2)** is selected and then choose the Runbook name: **ASRWEBFailover(3)**. Select **OK (4)**.

    ![Fields in the Insert action blade are set to the ASRWebFailover script.](images/Ex2-t1-step191.png "Insert Action blade")

      > **Note:** If the **OK** button does not respond, click the cross icon in the top-right corner, then click **Ok** in the dialog box. This will confirm that the post-action has been saved.

1. Make sure that your **Pre-steps** are running under **All groups failover** and the **Post-steps** are running under **Group1: Start**. Select **Save**.

    ![In the Recovery plan blade, both instances of Script: ASRFSQLFailover are called out under both All groups failover: Pre-steps, and Group 1: Post-steps.](images1/E2T4S18.png "Recovery plan blade")

1. After a minute, the portal will provide a successful update notification. This means that your recovery plan is fully configured and ready to failover and back between the primary and secondary regions.

    ![The Updating recovery plan message shows that the update was successfully completed.](images/image253.png "Updating recovery plan message")

1. Return to the Recovery Services Vault **BCDRRSV<inject key="DeploymentID" enableCopy="false"/>** blade and select the **Replicated Items** link under **Protected Items**. You should see **WebVM1** and **WebVM2**. The Replication Health should be **Healthy**. The Status will show the replication progress. Once both VMs show status **Protected**, replication is complete and you will be able to test the failover.

    ![Under Replicated Items, the status for WebVM1 is 97% Synchronized and WebVM2 is now Protected.](images1/E2T4S20upd1.png "Replicated Items")

    > **Note**: It can take up to 30 minutes for the replication to complete.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   > - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task. 
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help
   <validation step="c1c13d12-b3c0-487b-a713-8b1534088520" />

### Task 5: Configure a public endpoint using Azure Front Door

In this task, you will use the Front Door approach to configure a highly available endpoint that directs traffic to either your primary or secondary site, depending on which site is currently available.

1.  You will now build a Front Door to direct traffic to your Primary and Secondary Sites. From the Azure portal, select **+Create a resource**, then search for and select **Front Door and CDN profiles**. Select **Create**.

    ![frontdoor.](images/azfrontdoor.png "Replicated Items")

1. Select **Azure Front Door** and **Custom create**. Then select **Continue to create a  Front Door**.

    ![Screenshot showing compare offerings with Azure Front Door and Custom create both selected.](images1/E2T5S2.png "Azure Front Door Compare Offerings")
    
1. Complete the **Basics** tab of the **Create a Front Door** blade using the following inputs, then select **Next: Secrets > (4)**.

    - **Resource group**: Use existing / **ContosoRG1 (1)**
    - **Location**: Automatically assigned based on the region of **ContosoRG1**.
    - **Profile name**: **ContosoFD1 (2)**
    - **Tier**: **Standard (3)**

    ![Fields in the Create a Front Door blade are set to the previously defined settings.](images/E2-t5-s31.png "Create Front Door 'basics' blade")

1. Select **Next: Secrets >** leave it as default, and Select **Next: Endpoint >**

1. Select **Add an endpoint** to set the hostname of Front Door. In the **Add an endpoint** pane, enter the following values, then select **Add (2)**:

    - **Endpoint name**: **contosoiaas (1)**
    - **Status**: Leave **Enable this endpoint** selected

    ![Fields in the Add a frontend host pane are set to the previously defined settings.](images1/ex2-task5-step5upd.png "Add a frontend host pane.")

1. Under **Routes** select **+ Add a route**.

    ![Create a front door profile with options to create Routes and Security policies. Add a route is highlighted.](images1/E2T5S6.png "Create a front door profile")
    
1. Under Add a route page, select **Add a new origin group**.
    
    ![Under Origin group on the Add a new route screen, the link to Add a new origin group is highlighted.](images1/E2T5S7.png "Add a route")
    
1. Give the new origin group the name of `ContosoOrigins`.

1. Select **+ Add an origin**.
    
   ![Under the Add an origin group pane, + Add an origin is highlighted.](images1/E2T5S9.png "Add an origin group")
   
1. For adding an origin, use the following values. Leave all other values set to their default. Then select Add.

    - Name: `ContosoWebPrimary`
    - Origin type: Public IP Address
    - Host name: ContosoWebLBPrimaryIP
    - Priority: 1

    ![Screen shot showing the values entered into the Add an origin pane.](images1/origin1.png "Add an origin")

1. Repeat step 10 and change the values to the following.

    - Name: `ContosoWebSecondary`
    - Origin type: Public IP Address
    - Host name : ContosoWebLBSecondaryIP
    - priority: 2  

    ![Screen shot showing the values entered into the Add an origin pane.](images1/origin2.png "Add an origin")

1. Update **Interval (in seconds)** to 30. Click Add

    ![Showing the completed Add an origin group pane with all fields filled out and ready to select add.](images1/E2T5S12.png "Add an origin group")
    
1. Enter the following values in **Add a route**. Leave all other values as default. Select **Add (6)**

    - Name: **ContosoRoute (1)**
    - Accepted protocols: **HTTP only (2)**
    - Redirect: Uncheck **Redirect all traffic to use HTTPS (3)**
    - Origin group: ensure **ContosoOrigins (4)** is selected
    - Forwarding protocol: **HTTP only (5)**

    ![Screenshot showing the completed add a route pane with all correct values read to select Add.](images1/E2T5S131.png "Add a route")
    
1. Select **Review + Create**. Once validation has been completed, select **Create** to provision the Front Door service.

    ![Create a front door profile screen completed and ready to create. Completed route and Review + Create are highlighted.](images1/E2T5S14.png "Create a front door profile")
    
1. Navigate to the Azure Front Door resource. Select the **Frontend host** URL of Azure Front Door, and the Policy Connect web application will load. The web application is routing through the **ContosoWebLBPrimary** External Load Balancer configured in front of **WEBVM1** and **WEBVM2** running in the **Primary** Site in **ContosoRG1** resource group and connecting to the SQL AlwaysOn Listener at the same location.

    ![The Frontend host link is selected from the Azure Front Door.](images/E2T5S15.png "Frontend host link")

    ![The Contoso Insurance PolicyConnect webpage displays from a Front Door URL.](images1/E2T5S15.png "Contoso Insurance PolicyConnect webpage")

    > **Note:** Be sure to use **HTTP** to access the Azure Front Door **frontend host** URL. The lab configurations only support HTTP for Front Door since WebVM1 and WebVM2 are only set up for HTTP support, not HTTPS (no SSL\TLS).
    
    > **Note:** If you get an "Our services aren't available right now" error (or a 404-type error) accessing the web application, then continue with the lab and come back to this later. Sometime this can take a ~10 minutes for the routing rules to publish before it's "live".
    
    > If you continue to have this issue beyond 15 minutes, ensure that you are using the correct backend host header (Step 5) and using HTTP for both the routing rules and the health probes of the backend pools. (Step 4).

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   > - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task. 
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help
   <validation step="0bdbfd04-f20a-4db0-abae-810ff8964a34" />

## Summary 

In this exercise, you have deployed disaster recovery (DR) resources and inspected DR for the Domain Controller tier. DR was then configured for both the SQL Server and Web tiers, followed by the setup of a public endpoint using Azure Front Door.

### You have successfully completed the exercise
Now, click on **Next** from the lower right corner to move to the next page.
