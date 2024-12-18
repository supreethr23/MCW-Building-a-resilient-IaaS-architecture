# Exercise 2: Enable Disaster Recovery for the Contoso Application

### Estimated Duration: 60 Minutes

In this exercise, you will enable a secondary DR site. This site will support each tier of the Contoso application, using a different technology in each case. The DR approach is summarized in the following table.

### Objectives
In this exercise, you will complete the following tasks:
   - **Task 1:** Deploy DR Resources
   - **Task 2:** Inspect DR for the Domain Controller Tier
   - **Task 3:** Configure DR for the SQL Server Tier
   - **Task 4:** Configure DR for the Web Tier
   - **Task 5:** Configure a Public Endpoint Using Azure Front Door

### Task 1: Deploy DR Resources

In this task, you will deploy the resources the DR environment uses. First, you will deploy a template that creates the network and virtual machines. Then, you will manually deploy the Recovery Services vaults and Azure Automation account used by Azure Site Recovery.

1. Navigate to **[Cloud Shell](https://portal.azure.com/#cloudshell/)** in a new browser tab. Open a **PowerShell** session and create a Cloud Shell storage account if prompted.

    ![Screenshot of the Azure Cloud Shell with URL and PowerShell mode highlighted.](images1/cloudshellupd.png "Azure Cloud Shell")

1. In the **Getting started** page, select **Mount storage account (1)**, choose the **subscription (2)**, and click on **Apply (3)**.

   ![Screenshot of the Storage account storage.](images1/cloudshellstrg1.png "Azure Cloud Shell")

1. In the **Mount storage account** page, select **We will create a storage account for you (1)** and click **Next (2)**.

   ![Screenshot of the Storage account storage.](images1/cloudshellstrg2.png "Azure Cloud Shell")

1. Update the **-Location** parameter in each command below to specify a secondary location different from **ContosoRG1**. Then, execute the commands to create the Disaster Recovery (DR) resource group and deploy the DR resources. You can proceed to the following tasks while the template deployment progresses.

   ```powershell
   New-AzResourceGroup -Name 'ContosoRG2' -Location '<Enter the location>'
   New-AzSubscriptionDeployment -Name 'Contoso-IaaS-DR' -TemplateUri 'https://raw.githubusercontent.com/CloudLabs-MCW/MCW-Building-a-resilient-IaaS-architecture/prod/Hands-      on%20lab/Resources/templates/contoso-iaas-dr.json' -Location '<Enter the location>'
   ```

   > **Note:** If your deployment fails with an error *`"The requested size for resource '<resourceID>' is currently not available,"`* add the parameter `-skuSizeVM 'D2s_v5'` to the end of the `New-AzSubscriptionDeployment` and rerun the command:

   ```powershell
    # Only run this command if the previous deployment failed with an error that size was not available
    New-AzSubscriptionDeployment -Name 'Contoso-IaaS-DR-SKU' `
        -TemplateUri 'https://raw.githubusercontent.com/CloudLabs-MCW/MCW-Building-a-resilient-IaaS-architecture/prod/Hands-on%20lab/Resources/templates/contoso-iaas-dr.json' `
    -Location '<Enter the location>' -skuSizeVM 'D2s_v5'
    ```

1.  Take a few minutes to review the template while it is deployed. To review the template and deployment progress, navigate to the Azure portal home page, select **Resource Groups**, then **ContosoRG2** and **Deployments**. Note that the template includes:
    -  A DR virtual network that is connected using VNet peering to the existing virtual network.
    -  Two additional domain controller VMs, **ADVM3** and **ADVM4**.
    -  An additional SQL Server VM, **SQLVM3**.
    -  Azure Bastion to enable VM access.

    ![Screenshot of the disaster recovery resources for the Web application.](images1/E2T1S3.png "Successful deployment of Web DR resources")

1. Now, you will create the **Recovery Services vaults** used to replicate the web tier VMs and orchestrate the cross-site failover. From the Azure portal, search for **Recovery Services vaults (1)** and select **(2)** it.

    ![](images/E3T1S1upd.png)

1. On the **Recovery Services vaults** page, click on **+Create**.

    ![Screenshot of the Backup and Site Recovery Screen with the Create button selected.](images/recoveryselect.png "Backup and Site Recovery Screen Create Button")

1.  Complete the **Create Recovery Services vaults** page using the following inputs, then select **Review and Create (4)**:

    - **Resource Group**: **ContosoRG2 (1)**
    - **Name**: **BCDRRSV<inject key="DeploymentID" /> (2)**
    - **Location**: Your **secondary region (3)** that you choose in step 2

    ![Screenshot of the Backup and Site Recovery Screen with the Create button selected.](images/recoveryimg.png "Backup and Site Recovery Screen Create Button")

1.  Once the **BCDRRSV<inject key="DeploymentID" enableCopy="false"/>** Recovery Service vault has been created, open it in the Azure portal and select the **Site Recovery** tab.

    ![Screenshot of the Backup / Site Recovery tabs with Site Recovery tab selected.](images1/ex2-task1-step6.png "Backup / Site Recovery tabs")

1. This is your dashboard for **Azure Site Recovery (ASR)**.

    ![The Azure Site Recovery dashboard displays.](images1/ex2-task1-step7.png "Azure Site Recovery dashboard")

   > **Important:** Next, you will set up the Azure Automation account that will be used to automate certain failover and failback tasks. This will require several PowerShell scripts to be imported as Azure Automation runbooks. **Ensure that the following steps are executed from the LabVM since that is where the scripts are located.**

1.  From the Azure portal, select **+Create a resource**, followed by **IT & Management Tools**, then **Automation**.

1.  Complete the **Create an Automation Account** page using the following inputs and then select **Review + Create (4)**:

    - **Subscription**: Select the default subscription
    - **Resource group**: Use existing / **ContosoRG2** (1)
    - **Automation Account Name**: BCDR<inject key="DeploymentID" /> (2)
    - **Region**: your secondary region that you choose in step 2 (3)
    

    ![Fields in the Add Automation Account blade are set to the previously defined values.](images/updated111.png "Add Automation Account blade")

    > **Note:** Azure Automation accounts can only be created in certain Azure regions, but they can act on any region in Azure (except the Governments of China and Germany). It is not a requirement to have your Azure Automation account in the same region as the failover resources, but it **CANNOT** be in your primary region.

1. On the **Azure Automation Account** page, select **Runbooks (1)**, then click on **Import a runbook (2)**.

    ![The 'Import a runbook' button is highlighted in Azure Automation.](images1/E2T1S10upd1.png "Import a runbook button")

    > **Note**: You must be connected to the **LABVM** to complete the next steps.

1. Select the **Folder** icon on the **Import a runbook** blade and click on the file **ASRRunbookSQL.ps1** from the `C:\HOL\` directory on **LABVM**. Leave the **Runbook type** as **PowerShell Workflow**. Change the workflow name inside the **Runbook script** to **ASRSQLFailover** and select **Import**.

    ![Fields in the 'Import a runbook' blade are set to the previously defined values.](images/Ex2-t1-step15.png "Import a runbook")

1. Once the runbook is imported, the runbook editor will load. You can review the comments to understand the runbook better. Once ready, select **Publish**, followed by **Yes** at the confirmation prompt. This makes the runbook available for use.

    ![On the top menu of the Edit PowerShell Workflow Runbook blade, Publish is selected.](images1/E2T1S12.png "Publish runbook")

1. Repeat the above steps to import and publish the **ASRRunbookWEB.ps1** runbook and change the workflow name inside the Runbook script to **ASRWEBFailover.**

1. Navigate back to **Runbooks**, and ensure that both runbooks show as **Published**.

    ![Two runbooks have authoring status as published: ASRSQLFailover, and ASRWEBFailover.](images/updated12.png "Runbooks")

   > **Note:** When configuring the ASR Recovery Plan for the IaaS deployment, you will use the SQL Runbook as a pre-failover action and the web runbook as a post-failover action. They will run both ways and have been written to take the "direction" of the failover into account when running.

1. Next, you will create a variable in Azure Automation that contains settings (such as resource group names and VM names) describing your environment. The runbooks you imported require this information, and using variables allows you to avoid hard-coding it in the runbooks themselves.

1. In your **Azure Automation Account** page, select **Variables (1)**, then **Add a variable (2)**.

    ![Azure portal showing variables pane in Azure Automation.](images1/E2T1S15upd.png "Add a variable")

1. In the **New Variable** blade, enter `BCDRIaaSPlan` **(1)** as the variable name. The variable type should be **String**. Paste the following into the variable **Value (2)**, then select **Create (3)**.

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

1. Before continuing, check that the template deployment you started at the beginning of this task has been completed. From the Azure portal home page, select **Subscriptions**, select your subscription, then click on **Deployments (1)**. 

    ![The 'Contoso-IaaS-DR' template deployment shows as successful.](images1/E2T1S18upd.png "Template status")

   > **Congratulations** on completing the task! Now, it is time to validate it. Here are the steps:
   > - Click on the **Validate** button for the corresponding task. You can proceed to the next task if you receive a success message. 
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need assistance, please contact us at **cloudlabs-support@spektrasystems.com**. We are available 24/7 to help.
   <validation step="1134d3fd-1557-47f5-89db-4b6eebd50650" />

### Task 2: Inspect DR for the Domain Controller Tier

In this task, you will review the rest of the configuration to confirm everything is as it should be.

The failover site has been deployed with two additional domain controllers, **ADVM3** and **ADVM4**. These are integrated with the existing `contoso.com` domains hosted on **ADVM1** and **ADVM2** in the primary site. They run in a fully active-active configuration (therefore, no failover is required for this tier). The configuration of these domain controllers is fully automatic. 

1. From the Azure portal home page, select **Subscriptions,** choose your subscription, and click on **Deployments (1)**. Then, open the **Contoso-IaaS-DR (2)** deployment for the DR site.

    ![Click path to the 'Contoso-IaaS-DR' deployment.](images1/E2T2S1upd.png "DR deployment")

1.  Select **Template** and review the template contents. Note the use of `dependsOn` to control the deployment sequence carefully. The resources are deployed as follows:

    - The VNet2 virtual network is created.
    - VNet2 is peered with VNet1. This creates connectivity between the two networks.
    - The DNS settings in VNet2 are updated to point to the domain controllers in VNet1.
    - The new domain controllers, **ADVM3** and **ADVM4**, are deployed to VNet2 with static private IP addresses. A custom script extension configures these VMs as domain controllers.
    - The DNS settings in VNet2 are then updated to point to these new domain controllers.
    - Other VMs (such as **SQLVM3**) are now able to be deployed.

    ![Azure portal showing the Contoso-IaaS-DR template, with the deployment sequence highlighted.](images1/E2T2S2.png "DR template")

1.  Navigate to the **ContosoRG2** resource group. Click on the network interface (NIC) **ADVM3NIC** resources for the ADVM3 and ADVM4 VMs to confirm that their network settings include the static private IP addresses 10.1.3.100 and 10.1.3.101, respectively. On the left-hand side, under **Settings,** click on **IP configurations** and then select **ipconfig1**. Also, change the assignment to **Static** and update the IP address.

    ![Network interface configuration showing a static private IP address for ADVM3.](images1/ipconfig.png "Static IPs")

1. Navigate to the **VNet2** virtual network. Select **DNS servers** and confirm that the IP addresses for **ADVM3** and **ADVM4** are configured.

    ![The Azure portal shows the DNS settings for VNet2.](images1/E2T2S4.png "Template status")

1.  Select **Peerings** and confirm the network peers with VNet1.

    ![The Azure portal shows VNet2 is peered with VNet1.](images1/E2T2S5.png "VNet peering")


### Task 3: Configure DR for the SQL Server Tier

In this task, you will extend the SQL Server Always On Availability Group you created to include **SQLVM3** as an asynchronous replica running in the DR site.

1. Open an Azure Bastion session to **SQLVM3** in the Azure portal. Use `demouser` as the **username** and `Demo!pass123` as the **password**.

1. Launch **SQL Server Management Studio**. A new dialog box with **SQLVM3 (1)** as the server name will open. Ensure the **Trust server certificate (2)** is selected. Moving on, click on **Connect (3)** to sign on to **SQLVM3**. 

    > **Note**: The username for your lab should show **SQLVM3\demouser**.

    ![Screenshot of the Connect to Server dialog box.](images1/E3T3S27upd1.png "Connect to Server dialog box")
    
1. Expand **Security** and then **Logins**. You will notice that only `SQLVM3\demouser` is listed.

    ![In SQL Server management studio, SQLVM2 is expanded, then Security is expanded, then Login is expanded. Only the SQLVM2\demouser account is seen.](images1/E2T3S28upd1.png)

1. Right-click on **Logins** and then select **New Login...**

    ![The dialog box from the right-click on Logins is shown with an option to select New Login.](images1/E1T3S29upd.png)

1. **Login name: (1)** type **contoso\demouser**, then select **Server Roles (2)**.

    ![The Login-New dialog box is displayed. In the Login name: box, the username contoso\demouser has been typed in. From here, it shows you selected the Server Roles tab in the left side navigation.](images1/E1T3S30.png)

1. Check the box for **sysadmin** and select **OK**.

    ![The Server Roles tab is shown in the Login - New dialog box. In this dialog box, public remains checked, and a check is added to the sysadmin option.](images1/E1T3S31.png)

1. Return to the Azure portal and navigate to the **ContosoSQLLBSecondary** load balancer blade in **ContosoRG2**. Select **Backend pools** and open **BackEndPool1**. Note that the pool is connected to the **VNet2** virtual network. Select **+ Add**.

   ![Azure portal showing where to select Add on the ContosoSQLLBSecondary load balancer backend pool to add a new VM.](images/EX2-T3-S1.png "Backend pool")

1. Select **SQLVM3** and click on **Add**.  Select **Save** on **BackEndPool1** to save changes.

     ![Azure portal showing SQLVM3 being added to the ContosoSQLLBSecondary load balancer backend pool.](images1/E2T3S2.png "SQL VM added to backend pool")

   >**Note:** The DR site is configured with a single SQL Server VM for this lab. Therefore, using a load balancer is not strictly required. However, if necessary, it allows the DR site to be extended to include its own HA cluster.

1. Return to your browser tab containing your Bastion session with **SQLVM1**. (If you have closed the tab, reconnect using Azure Bastion with the **username** `demouser@contoso.com` and **password** `Demo!pass123`.)

1. On **SQLVM1**, use **Windows PowerShell ISE** to execute the following command. This will add **SQLVM3** as a node in the Windows Server Failover Cluster.

    ```PowerShell
    Add-ClusterNode -Name SQLVM3
    ```

1. Select **Start** and then **Windows Administrative Tools**. Locate and open the **Failover Cluster Manager**. Expand **AOGCLUSTER** and select **Nodes**. **SQLVM3** is now included in the list, with the status: **Up**.

    ![In Failover Cluster Manager, Nodes is selected in the tree view, and three nodes display in the details pane.](images/dr-fcm-3nodes.png "Failover Cluster Manager")

1.  Return to the Azure portal. Locate **SQLVM3** and connect to the VM using Azure Bastion with the **username** `demouser@contoso.com` and **password** `Demo!pass123`.

1.  On **SQLVM3**, select **Start** and launch **SQL Server 2017 Configuration Manager**.

    ![Screenshot of the SQL Server 2017 Configuration Manager option on the Start menu.](images/image166upd.png "SQL Server 2017 Configuration Manager option")

1.  Select **SQL Server Services (1)**, then right-click on **SQL Server (MSSQLSERVER) (2)** and choose **Properties (3)**.

    ![In SQL Server 2017 Configuration Manager, in the left pane, SQL Server Services is selected. In the right pane, SQL Server (MSSQLSERVER) is selected, and from its right-click menu, Properties is selected.](images/image167upd.png "SQL Server 2017 Configuration Manager")

1.  Select the **AlwaysOn High Availability (1)** tab and check the box to **Enable AlwaysOn Availability Groups (2)**. Select **Apply (3)** and then click **OK** on the message that notifies you that the changes will take effect after the server is restarted.

    ![In the SQL Server Properties dialog box, on the AlwaysOn High Availability tab, the Enable AlwaysOn Availability Groups checkbox is checked and the Apply button is selected.](images/image168.png "SQL Server Properties dialog box")

    ![A pop-up warns that any changes made will not take effect until the service stops and restarts. The OK button is selected.](images/image169.png "Warning pop-up")

1. On the **Log On** tab, change the service account to `contoso\demouser` using `Demo!pass123` as the **password**. Select **OK** to accept the changes, and then select **Yes** to confirm the restart of the server.

    ![In the SQL Server Properties dialog box, on the Log On tab, fields are set to the previously defined settings. The OK button is selected.](images1/E2T3S10.png "SQL Server Properties dialog box")

    ![A pop-up asks you to confirm that you want to make the changes and restart the service. The Yes button is selected.](images/image171.png "Confirm Account Change pop-up")
    
1. Return to your session with **SQLVM1**. Open **Microsoft SQL Server Management Studio 20** and connect to the local instance of SQL Server.

1. Expand the **Always On High Availability** node. Under **Availability Group Listeners**, right-click on **BCDRAOG** and select **Properties**.

    ![On the BCDRAOG Listener context menu, 'Properties' is selected.](images1/E2T3S12.png "Listener properties")

1. On the BCDRAOG Listener properties dialog box, select **Add**.

    ![On the BCDRAOG Listener properties dialog, 'Add' is selected.](images1/E2T3S13.png "Listener - Add")

1. On the Add IP Address dialog box, check that the subnet is **10.1.2.0/24** (the Data subnet in VNet2). Enter the IP address **10.1.2.100** (the frontend IP of the SQL load balancer in VNet2). Select **OK**.

    ![On the BCDRAOG Listener Add IP Address dialog, the IP address is entered as specified.](images1/E2T3S14.png "Listener - IP")

1. The **BCDRAOG Listener properties** dialogue box should now show two IP addresses. Select **OK** to close the box and commit the change.

    ![On the BCDRAOG Listener properties dialog, two IP addresses are shown. 'OK' is selected.](images1/E2T3S15.png "Listener - two IPs")

1. Under **Availability Groups**, right-click on **BCDRAOG (Primary)** and select **Add Replica..** to open the Add Replica wizard.

    ![In Object Explorer, under Always On High Availability the BCDRAOG availability group is selected, and from its right-click menu, Add Replica is selected.](images1/E2T3S16upd.png "SQL Server Management Studio - Add Replica")

1. Select **Next** on the Wizard.

    ![On the Add Replica Wizard 'Introduction' page, Next is selected.](images1/E2T3S17.png "Add Replica wizard")

1. Select **Connect** to connect to SQLVM2, then **Connect** again on the 'Connect to Server' prompt, and click **Next**.

    ![On the Add Replica Wizard 'Connect to Replicas' page, SQLVM2 is connected and Next is selected.](images1/E2T3S18.png "Connect to Replicas page")

1. On the **Specify Replicas** page, select **Add Replica...**.

    ![Screenshot of the Add replica button.](images1/E2T3S19.png "Add replica button")

1. In the **Connect to Server** dialog box, enter the Server name as **SQLVM3 (1)**, check the box beside **Trust server certificate (2)**, and select **Connect (3)**.

    ![Screenshot of the Connect to Server dialog box.](images1/E3T3S27upd1.png "Connect to Server dialog box")

1. For **SQLVM3**, leave the default settings of 'Asynchronous commit' with 'Automatic Failover' disabled. Then, select **Next**.

    ![The SQLVM3 replica settings are asynchronous commit with automatic failover disabled. The Next button is highlighted.](images1/E2T3S21.png "SQLVM3 replica settings")

1. On the **Select Data Synchronization** page, make sure that **Automatic seeding** is selected and click on **Next**.

    ![On the Select Data Synchronization page, the radio button for Automatic seeding is selected. The Next button is selected at the bottom of the form.](images1/E2T3S22.png "Select Data Synchronization page")

1. On the **Validation** screen, everything should be green except for a warning for 'Checking the listener configuration.' This will be addressed later. To proceed, select **Next**.

    ![The Validation screen displays a list of everything it is checking, and the results for each, which all display success except the last one. The Next button is selected.](images1/E2T3S23.png "Validation screen")

1. On the **Summary page**, select **Finish**.

    ![On the Summary page, the Finish button is selected.](images1/E2T3S241.png "Summary page")

1. Once the AOG is built, check that each task has "**successful**" written beside it and select **Close**.

    ![On the Results page, a message says the wizard has completed successfully, and results for all steps is success. The Close button is selected.](images1/E2T3S25.png "Results page")

1. Under **Availability Groups**, right-click on **BCDRAOG (Primary)** and then select **Show Dashboard**. You should see that the **SQLVM3** node has been added and is synchronizing.

    ![Screenshot of the BCDRAOG Dashboard showing SQLVM3 synchronizing.](images1/E2T3S26upd.png "BCDRAOG Dashboard")

1. Move back to **PowerShell ISE** on **SQLVM1**. Open a new file, paste it into the following script, and select the **Play** button. This will update the failover cluster with the new listener IP address that you had created.

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

1. Return to **Failover Cluster Manager** on **SQLVM1**, select **Roles (1)**, then **BCDRAOG (2)**. Notice how the **Resources (3)** tab shows that the new IP address **10.1.2.100** has been added and is currently offline.

    ![In the Failover Cluster Manager tree view, Roles is selected. Under Roles, BCDRAOG is selected, and details of the role display.](images1/E2T3S281.png "Failover Cluster Manager")


### Task 4: Configure DR for the Web Tier

You will configure DR for the Contoso application web tier in this task.

The web tier DR solution uses Azure Site Recovery to replicate the primary site web tier VMs to Azure storage. During failover, the replicated data is used to create new VMs in the DR site, which are preconfigured with the virtual network and web tier load balancer.

Azure Site Recovery calls custom scripts in Azure Automation to add the recovered web VMs to the load balancer and failover the SQL Server.

1. From the Azure portal on **LABVM**, open the **BCDRRSV<inject key="DeploymentID" enableCopy="false"/>** Recovery Services vault located in the **ContosoRG2** resource group.

1. Under **Getting Started**, select **Site Recovery (1)**.  Next, choose **Step 1: Enable replication (2)** in the **For On-Premises Machines and Azure VMs** section. 

    ![In the ASR blade, Getting Started is highlighted. Under For On-Premises Machines and Azure VMs, Step 1: Enable replication is selected.](images/dr-asr-1upd.png "Step 1 selected")

1. In **Step 1 - Source,** select the following inputs and then click on **Next (5)**:

    - **Location**: **<inject key="Region" enableCopy="false" />** (Primary region) **(1)**.
    - **Resource group**: ContosoRG1 **(2)**.
    - **Virtual machine deployment model**: Resource Manager **(3)**.
    - **Disaster Recovery between Availability Zones?**: No (this option is for DR between availability zones *within* a region) **(4)**.

    ![In the Source blade, fields are set to the previously defined settings.](images/EX2-T4-S31.png "Source blade")

1. On **Step 2 - Virtual Machines**, select **WebVM1** and **WebVM2** and click **Next**.

    ![In the Select virtual machines blade, the check boxes for WebVM1 and WebVM2 are selected.](images/EX2-T4-S4.png "Select virtual machines blade")

1. Select the following inputs on the **Step 3 - Replication settings** tab and click **Next (4).**  
   - **Target location**: *Select the secondary region you had selected previously* **(1)**.
   - **Target resource group**: ContosoRG2 **(2)**.
   - **Failover virtual network**: VNet2 **(3)**.

    ![In the Customize target settings blade, the Target location is set to East US 2 and the customize button highlighted](images/EX2-T5-S3.png "Configure settings blade")

1.  Select the following inputs for **Step 4: Manage** tab and click **Next (3)**.

    - **Update settings**: Allow ASR to manage **(1)**.
    - **Automation Account**: use your existing Automation Account **(2)**.
    
    ![The Replication Policy settings use default values.](images/EX2-T4-ns31.png "Replication policy")

1. Next, in **Step 5** in the **Review** tab, select **Enable replication**.

    ![Screenshot of the Enable replication button.](images/EX2-T3-S9.png "Enable replication button")

1. The Azure portal will start the deployment. This will take approximately 10 minutes to complete. Wait for replication to complete before moving to the next step.

    ![A message is displayed indicating Enabling replication for two vm(s) has successfully completed.](images/image234.png "Enabling replication for two vm(s)")

    > **Note:** Monitor the jobs if the replication status indicates failure **(1)**. You can move on to the next step if all jobs are successful **(2)**.
    >  ![A message is displayed indicating replication failure.](images/failurerep.png "Enabling replication for two vm(s)")

1. The **BCDRRSV<inject key="DeploymentID" enableCopy="false"/>** blade should still have the **Site Recovery (1)** option selected under **Getting started**. Then, choose **2: Manage recovery plans (2)**.

    ![Click path to Manage Recovery Plans.](images/dr-asr-8.png "Manage Recovery Plans")

1. Select **+Recovery plan**.

    ![On the Recovery Services vault blade top menu, Add a recovery plan is selected.](images1/E2T4S10upd.png "Add recovery plan")

1. Fill in the **Create recovery plan** blade as follows and click on **Create (5)**:

    - **Name**: BCDRIaaSPlan **(1)**.
    - **Source**: **<inject key="Region" enableCopy="false" />** *(This is your primary region)* **(2)**.
    - **Target**: *Secondary region that you had selected* **(3)**.
    - **Allow items with deployment model**: Resource Manager **(4)**.
    - **Selected Items**: Select **WebVM1** and **WebVM2**.

        ![Fields in the Create recovery plan blade are set to the previously defined settings.](images1/E2T4S111.png "Create recovery plan blade")

    > **Note:** Using the correct recovery plan name `BCDRIaaSPlan` is **critical**. This must match the name of the Azure Automation variable you had created earlier as part of the first task in this exercise.

1. Select **OK** to create the recovery plan. After a moment, the **BCDRIaaSPlan** recovery plan will appear. Select it to review.

    ![In the Recovery Plans blade, BCDRIaaSPlan is selected.](images1/E2T4S12.png "Recovery plans")

1. When the **BCDRIaaSPlan** loads, **notice** that it shows **2 VMs in the Source,** which is your **Primary** Site.

    Now, customize the recovery plan to trigger the SQL failover and configure the web tier load balancer during the failover process. Next, select **Customize**.

    ![On the BCDSRV blade top menu, Customize is selected. Under Items in recovery plan, the source shows two and the VM icon.](images1/E2T4S131.png "BCDSRV blade")

1. Once the **BCDRIaaSPlan** blade loads, select the **ellipsis (2)** icon next to **All groups failover (1)**. Click on **Add pre-action (3)** from the context menu.

    ![In the Recovery plan blade, the right-click menu for All groups failover displays and Add pre-action is selected.](images1/E2T4S141.png "Recovery plan blade")

1. Select **Script** on the **Insert action** blade, and then insert the name as **ASRSQLFailover (1).** Ensure that your **Azure Automation account (2)** is selected. Choose the runbook name **ASRSQLFailover (3)**. Click on **OK (4)**.

    ![Fields in the Insert action blade are set to the ASRRunBookSQL script.](images/Ex-2-t3-step171.png "Insert action blade")

    > **Note:** As noted on the 'Insert action' blade, the ASRSQLFailover runbook will be executed on both failover and failback. The runbook has been written to support both scenarios.
    > 
    > **Note:** If the **OK (2)** button does not respond, click the **cross icon (1)** in the top-right corner, then click **OK** in the dialog box. This will confirm that the pre-action has been saved.
    > ![issueimage.](images1/cancelbutton.png "Recovery plan blade")

1. Once the **BCDRIaaSPlan** blade loads, select the **ellipsis** icon next to **Group 1: Start**, then select **Add post action** from the context menu.

    ![In the Recovery plan blade, the Group 1: Start right-click menu displays, and Add post action is selected.](images1/E2T4S16.png "Recovery plan blade")

1. Select **Script** on the **Insert action** blade, then provide the name **ASRWEBFailover (1)**. Ensure that your **Azure Automation account (2)** is selected, and then choose the runbook name **ASRWEBFailover (3)**. Select **OK (4)**.

    ![Fields in the Insert action blade are set to the ASRWebFailover script.](images/Ex2-t1-step191.png "Insert Action blade")

      > **Note:** If the **OK** button does not respond, click the **cross icon** in the top-right corner, then click **OK** in the dialog box. This will confirm that the post-action has been saved.

1. Ensure that your **Pre-steps** are running under **All groups failover** and the **Post-steps** are running under **Group 1: Start**. Select **Save**.

    ![In the Recovery plan blade, both instances of Script: ASRFSQLFailover are called out under both All groups failover: Pre-steps, and Group 1: Post-steps.](images1/E2T4S18.png "Recovery plan blade")

1. After a minute, the portal will provide a successful update notification. Your recovery plan is fully configured and ready to failover between the primary and secondary regions.

    ![The Updating recovery plan message shows that the update was successfully completed.](images/image253.png "Updating recovery plan message")

1. Return to the Recovery Services vault **BCDRRSV<inject key="DeploymentID" enableCopy="false"/>** blade and select the **Replicated Items** link under **Protected Items**. You should see **WebVM1** and **WebVM2**. The replication health should be **healthy**. The **Status** will show the replication progress. Once both VMs show the status as **Protected**, replication is complete, and you can test the failover.

    ![Under Replicated Items, the status for WebVM1 is 97% Synchronized and WebVM2 is now Protected.](images1/E2T4S20upd1.png "Replicated Items")

    > **Note**: It can take up to 30 minutes for the replication to complete.

   > **Congratulations** on completing the task! Now, it is time to validate it. Here are the steps:
   > - Click on the **Validate** button for the corresponding task. You can proceed to the next task if you receive a success message. 
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at **cloudlabs-support@spektrasystems.com.** We are available 24/7 to help.
   <validation step="c1c13d12-b3c0-487b-a713-8b1534088520" />

### Task 5: Configure a Public Endpoint using Azure Front Door

In this task, you will use the Front Door approach to configure a highly available endpoint that directs traffic to your primary or secondary site, depending on availability.

1.  You will build a front door to direct traffic to your primary and secondary sites. From the Azure portal, select **+Create a resource**, then search for and select **Front Door and CDN profiles (1)**. Select **Create (2)**.

    ![frontdoor.](images/azfrontdoor.png "Replicated Items")

1. Select **Azure Front Door** and **Custom create**. Then select **Continue to create a Front Door**.

    ![Screenshot showing compare offerings with Azure Front Door and Custom create both selected.](images1/E2T5S2.png "Azure Front Door Compare Offerings")
    
1. Complete the **Basics** tab of the **Create a Front Door** blade using the following inputs, then select **Next: Secrets > (4)**.

    - **Resource group**: Use existing/**ContosoRG1 (1)**
    - **Location**: Automatically assigned based on the region of **ContosoRG1**.
    - **Profile name**: **ContosoFD1 (2)**
    - **Tier**: **Standard (3)**

    ![Fields in the Create a Front Door blade are set to the previously defined settings.](images/E2-t5-s31.png "Create Front Door 'basics' blade")

1. Select **Next: Secrets >** leave it as default, and click on **Next: Endpoint >**

1. Select **Add an endpoint** to set the hostname of the **Front Door**. In the **Add an endpoint** pane, enter the following values, then select **Add (2)**:

    - **Endpoint name**: **contosoiaas (1)**
    - **Status**: Leave **Enable this endpoint** selected

    ![Fields in the Add a frontend host pane are set to the previously defined settings.](images1/ex2-task5-step5upd.png "Add a frontend host pane.")

1. Under **Routes,** select **+ Add a route**.

    ![Create a front door profile with options to create Routes and Security policies. Add a route is highlighted.](images1/E2T5S6.png "Create a front door profile")
    
1. Under the **Add a route** page, select **Add a new origin group**.
    
    ![Under Origin group on the Add a new route screen, the link to Add a new origin group is highlighted.](images1/E2T5S7.png "Add a route")
    
1. Give the new origin group the name of `ContosoOrigins`.

1. Select **+ Add an origin**.
    
   ![Under the Add an origin group pane, + Add an origin is highlighted.](images1/E2T5S9.png "Add an origin group")
   
1. Use the following values to add an origin. Leave all other values set to their default. Then select **Add (5)**.

    - **Name**: `ContosoWebPrimary` **(1)**
    - **Origin type**: Public IP Address **(2)**
    - **Host name**: ContosoWebLBPrimaryIP **(3)**
    - **Priority**: 1 **(4)**

    ![Screen shot showing the values entered into the Add an origin pane.](images1/origin1.png "Add an origin")

1. Repeat step 10, change the values to the following, and click on **Add (5)**.

    - **Name**: `ContosoWebSecondary` **(1)**
    - **Origin type**: Public IP Address **(2)**
    - **Host name**: ContosoWebLBSecondaryIP **(3)**
    - **Priority**: 2  **(4)**

    ![Screen shot showing the values entered into the Add an origin pane.](images1/origin2.png "Add an origin")

1. Update **Interval (in seconds)** to 30. Click Add

    ![Showing the completed Add an origin group pane with all fields filled out and ready to select add.](images1/E2T5S12.png "Add an origin group")
    
1. Enter the following values under **Add a route**. Leave all other values as default. Select **Add (6)**

    - Name: **ContosoRoute (1)**
    - Accepted protocols: **HTTP only (2)**
    - Redirect: Uncheck **Redirect all traffic to use HTTPS (3)**
    - Origin group: ensure **ContosoOrigins (4)** is selected
    - Forwarding protocol: **HTTP only (5)**

    ![Screenshot showing the completed add a route pane with all correct values read to select Add.](images1/E2T5S131.png "Add a route")
    
1. Select **Review + Create**. Once validation has been completed, select **Create** to provision the Front Door service.

    ![Create a front door profile screen completed and ready to create. Completed route and Review + Create are highlighted.](images1/E2T5S14.png "Create a front door profile")
    
1. Navigate to the **Azure Front Door** resource. Select the **Frontend host** URL of Azure Front Door, and the **Policy Connect** web application will load. The web application is routing through the **ContosoWebLBPrimary** external load balancer configured in front of **WEBVM1** and **WEBVM2** running in the **Primary** site of the **ContosoRG1** resource group and connecting to the **SQL AlwaysOn Listener** at the same location.

    ![The Frontend host link is selected from the Azure Front Door.](images/E2T5S15.png "Frontend host link")

    ![The Contoso Insurance PolicyConnect webpage displays from a Front Door URL.](images1/E2T5S15.png "Contoso Insurance PolicyConnect webpage")

    > **Note:** Use **HTTP** to access the Azure Front Door **frontend host** URL. The lab configurations only support HTTP for Front Door since WebVM1 and WebVM2 are only set up for HTTP support, not HTTPS (no SSL\TLS).
    
    > **Note:** If you get an "Our services aren't available right now" error (or a 404-type error) accessing the web application, then continue with the lab and come back to this later. The routing rules can sometimes take ~10 minutes to publish before it's "live."
    
    > If you continue to have this issue beyond 15 minutes, ensure that you are using the correct backend host header (Step 5) and HTTP for both the routing rules and the health probes of the backend pools. (Step 4).

   > **Congratulations** on completing the task! Now, it is time to validate it. Here are the steps:
   > - Click on the **Validate** button for the corresponding task. You can proceed to the next task if you receive a success message. 
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at **cloudlabs-support@spektrasystems.com.** We are available 24/7 to help.
   <validation step="0bdbfd04-f20a-4db0-abae-810ff8964a34" />

## Summary 

In this exercise, you have deployed Disaster Recovery (DR) resources and inspected DR for the Domain Controller tier. DR was then configured for both the SQL Server and web tiers, followed by setting up a public endpoint using Azure Front Door.

### You have successfully completed the exercise.
Click **Next** from the lower right corner to move to the next page.
