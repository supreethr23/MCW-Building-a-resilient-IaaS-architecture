# Exercise 1: Enable High Availability for the Contoso Application

### Estimated Duration: 90 Minutes

In this exercise, you will convert the Contoso application's deployment in the <inject key="Region" enableCopy="false" /> region into a highly available architecture by adding redundancy to each tier, including the web, database, and domain controller VMs.

### Objectives
In this exercise, you will complete the following tasks:
   - **Task 1:** Deploy HA Resources
   - **Task 2:** Configure HA for the Domain Controller Tier
   - **Task 3:** Configure HA for the SQL Server Tier
   - **Task 4:** Configure HA for the Web Tier

### Task 1: Deploy HA Resources

In this task, you will deploy additional web, database, and domain controller VMs.
A template will be used to save time. You will configure each tier in subsequent exercises in this lab.

1. Copy the link provided and paste it into a browser inside the VM. This will help you launch the template deployment for the additional infrastructure components, and that further will be used to enable high availability for the Contoso application. Log in to the Azure portal using your subscription credentials.
   
    [![Button to deploy the Contoso High Availability resource template to Azure.](https://aka.ms/deploytoazurebutton "Deploy the Contoso HA resources to Azure")](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FCloudLabs-MCW%2FMCW-Building-a-resilient-IaaS-architecture%2Fprod%2FHands-on%20lab%2FResources%2Ftemplates%2Fcontoso-iaas-ha.json)

1.  Insert the details provided into the **Custom deployment** blade:

    - Resource Group: **ContosoRG1 (1)** (existing)
    - Location: **<inject key="Region" enableCopy="false"/>** (2).

    Select **Review + Create (3)** and then click on **Create** to deploy resources.

    ![The custom deployment screen with ContosoRG1 as the resource group.](images/iaas-image1.png "Custom deployment")

1.  While you wait for the HA resources to get deployed, take some time to review the template contents. You can review the template by navigating to the **ContosoRG1** resource group. Click on **Deployments** in the resource group, and then select any of the deployments, followed by **template**.

    ![Screenshot of the Azure portal showing the HA template contents.](images/Deployment02.png "Screenshot of the Azure portal showing the HA template contents.")

    Note that the template includes five sub-templates containing the various resources required for:

    -   The ADVM2 virtual machine, which will be a second Domain Controller.
    -   The SQLVM2 virtual machine, which will be a second SQL Server.
    -   The WebVM2 virtual machine, which will be a second web server.
    -   Two load balancers, one for the web tier and one for the SQL tier.
    -   The virtual network with the proper DNS configuration in place.

1.  You can check the HA resource deployment status by navigating to the **ContosoRG1** resource group. Select **Deployments** in the resource group and check the status of the deployments. Make sure the deployment status is marked as **Succeeded** for all available templates before proceeding to the next task.

    ![Screenshot of the Azure portal showing the template deployment status 'Succeeded' for each template.](images/iaas-image2.png "Screenshot of the Azure portal showing the template deployment status Succeeded for each template")


   > **Congratulations** on completing the task! Now, it is time to validate it. Here are the steps:
   > - Click on the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task. 
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at **cloudlabs-support@spektrasystems.com**. We are available 24/7 to help.
   <validation step="ccb0033a-ade9-4c32-a114-01ddcf952476" />

### Task 2: Configure HA for the Domain Controller Tier

In this task, you will reboot all the virtual machines to ensure they receive the updated DNS settings.

When using a domain controller VM in Azure, other VMs in the virtual network must be configured to use the domain controller as their DNS server. This is achieved by setting the DNS settings in the virtual network. These settings are then picked up by the VMs when they reboot or renew their DHCP lease.

The initial deployment included a first domain controller VM, **ADVM1**, with a static private IP address **10.0.3.100**. Moving on, the IP address was configured in the VNet DNS settings.

The HA resources template has added a second domain controller, **ADVM2**, with a static private IP address **10.0.3.101**. This server has already been promoted to be a domain controller using a CustomScriptExtension (you can review this script if you like, you will find it linked from the ADVM2 deployment template). The template also updated the DNS setting on the virtual network to include the IP address of the second domain controller.


1. In the **search resources, services, and docs (G+/)** box at the top of the portal, enter **Virtual machines (1)** and then select **Virtual machines (2)** from the results.

     ![](images/iaas-image3.png "Screenshot of the Azure portal searching and selecting virtual machine")

1. Restart the **ADVM1** and **ADVM2** virtual machines in the **ContosoRG1** resource group. When prompted to **Restart this virtual machine**, click **Yes** to ensure they pick up the new DNS server settings.
   
    ![Restart the VM.](images/iaas-image4.png "Custom deployment")

    ![Restart the VM.](images/iaas-image5.png "Custom deployment")

1. Wait a minute or two for the domain controller VMs to boot fully, then restart the **WebVM1**, **WebVM2**, **SQLVM1**, and **SQLVM2** virtual machines so they also pick up the new DNS server settings.


### Task 3: Configure HA for the SQL Server Tier

In this task, you will build a **Windows Failover Cluster** and configure **SQL Always On Availability Groups** to create a high availability database tier.


1. In the **search resources, services, and docs (G+/)** box at the top of the portal, enter **Storage accounts (1)** and then select **Storage accounts (2)** from the results.

   ![](images/iaas-image6.png)

1. Click on **Create**.   

   ![](images/iaas-image7.png)

1. Fill in the following details in the **Create a storage account** page and click on **Next (7)**:

    - **Resource Group**: ContosoRG1 (1)
    - **Storage Account Name:** contososqlwitness<inject key="DeploymentID" enableCopy="false"/> (2)
    - **Location**: Any location in your area that is **NOT** your primary or secondary site, for example, **West US 2** (3)
    - **Primary Service**: Azure Files (4)
    - **Performance**: Standard (5)
    - **Replication**: Zone-redundant storage (ZRS) (6)

    ![](images/iaas-image8.png)

1.  Switch to the **Advanced** tab. Select the checkbox next to **Allow enabling anonymous access on individual containers (1)**, change the **Minimum TLS version** to **Version 1.0 (2)**, and select **Review + create (3)**, followed by clicking on the **Create** option.

    ![](images/iaas-image9.png)

    > **Note:** To promote the use of the latest and most secure standards, by default Azure storage accounts require TLS version 1.2. This storage account will be used as a Cloud Witness for our SQL Server cluster. SQL Server requires TLS version 1.0 for the Cloud Witness.

1.  Once the storage account is created, navigate to the **Storage account** blade. Expand **Security + networking (1)** and select **Access keys (2)**, then copy the **Storage account name (3)** and click on **show keys**. Moving on, copy the **key (4)** and paste values into your text editor of choice - you will need these values later.

    ![](images/iaas-image10.png)

1. Navigate back to the **ContosoRG1** Resource group, and select the **ContosoSQLLBPrimary** Load balancer.

     ![](images/iaas-image11.png)

1. On the **ContosoSQLLBPrimary** Load balancer blade, expand **Settings (1)**, then select **Backend pools (2)** and open **BackEndPool1 (3)**.

    ![](images/iaas-image12.png)

1.  In the **BackendPool1** blade, select **+ Add (1)** and choose the two **SQL VMs (2)**. Select **Add (3)** to close. Moving on, click on **Save (4)** to add these SQL VMs to **BackEndPool1**.

    ![](images/iaas-image13.png)

    ![](images/iaas-image14.png)

    > **Note:** The load balancing rule in the load balancer has been created with **Floating IP (direct server return)** enabled. This is important when using the Azure Load Balancer for SQL Server AlwaysOn Availability Groups.

1.  From the Azure portal, navigate to the **SQLVM1** Virtual machine. Expand **Connect (1)**, then choose **Bastion (2)**. Specify the following credentials and then click on **Connect (5)**.

    - **Username**: `demouser@contoso.com` (3)
    - **Password**: `Demo!pass123` (4)
    
    ![](images/iaas-image15.png)

    > **Note:** When using Azure Bastion to connect to a VM using domain credentials, the username must be specified in `user@domain-fqdn` format and **not** as `domain\user`.

    ![](images/iaas-image16.png)
    
    >**Note:**: Before selecting **Allow** make sure to recheck the text and images copied to the clipboard prompted.

1.  On **SQLVM1**, select **Start (1)** and then choose **Windows PowerShell ISE (2)**.

     ![](images/iaas-image17.png)

    >**Note**: Please minimize the **Server Manager** window 

1.  Copy and paste  the following command into **PowerShell ISE** and execute it. This will create the **Windows Failover Cluster** and add all the SQL VMs as nodes in the cluster. It will also assign a static IP address of **10.0.2.99** to the new cluster named **AOGCLUSTER**.

     ```PowerShell
     New-Cluster -Name AOGCLUSTER -Node SQLVM1, SQLVM2 -StaticAddress 10.0.2.99
     ```

     ![](images/iaas-image18.png)

    >**Note:** It is possible to use a wizard for this task, but the resulting cluster will require additional configuration to set the static IP address in Azure.

1. On **SQLVM1**, after the cluster has been created, select **Start (1)** and then **search (2) Failover**. Finally, open the **Failover Cluster Manager**.

    ![](images/iaas-image19.png)

1. When the cluster opens, select **AOGCLUSTER.contoso.com (1)** > **Nodes (2)**, and the SQL Server VMs will appear as nodes of the cluster, followed by their status as **Up (3)**.

    ![](images/iaas-image20.png)

1. If you select **Roles**, you will notice that currently, there aren't any roles assigned to the cluster.

    ![](images/iaas-image21.png)

1. Select **Networks (1)**, and you will see **Cluster Network 1 (2)** with the status **Up**. On navigating more through the **Networks** page, you will see the IP address space, and on the lower tab, you can select **Network Connections (3)** besides reviewing the nodes **(4)**.

    ![](images/iaas-image22.png)

1. Right-click on **AOGCLUSTER (1),** then select **More Actions (2)**, followed by **Configure Cluster Quorum Settings (3)**.

    ![](images/iaas-image23.png)

1. On the **Before You Begin** wizard, click **Next**.

    ![](images/iaas-image24.png)
     
1. On the **Select Quorum Configuration Option** wizard, choose **Select the quorum witness (1)**. Then, click on **Next (2)** again.

    ![](images/iaas-image25.png)

1. On the **Select Quorum Witness** wizard, select **Configure a Cloud Witness (1)** and **Next (2)**.

    ![](images/iaas-image26.png)

1. On the **Configure Cloud Witness** wizard, copy the **Azure storage account name (1)** and **Azure storage account key (2)** values that you noted earlier. Now, paste them into their respective fields on the form. Leave the Azure service endpoint as configured. Then, select **Next (3)**.

    ![](images/iaas-image27.png)

1. Select **Next** on the **Confirmation** screen.

    ![](images/iaas-image28.png)

1. Select **Finish**.

    ![](images/iaas-image29.png)

1. Select the name of the cluster again, and the **Cloud Witness** should now appear in the **Cluster Resources** section (you may need to scroll down). It is important to always use a third data center. In your case, here is a third Azure Region to be your Cloud Witness.

     ![](images/iaas-image30.png)

1. Select **Start (1)**, **search SQL Server 2017 Configuration Manage (2)** and launch **SQL Server 2017 Configuration Manager (3)**.

    ![](images/iaas-image31.png)

1. Select **SQL Server Services (1)**, then right-click on **SQL Server (MSSQLSERVER) (2)** and select **Properties (3)**.

    ![](images/iaas-image32.png)

1. Select the **AlwaysOn High Availability (1)** tab and check the box for **Enable AlwaysOn Availability Groups (2)**. Select **Apply (3)** and then select **OK (4)** on the message that notifies you that changes won't take effect until the service is stopped and restarted.

    ![](images/iaas-image33.png)

    ![](images/iaas-image34.png)

1. Click on the **Log On (1)** tab to change the service account to `contoso\demouser` **(2)** with the password `Demo!pass123` **(3)**. Select **OK (4)** to accept the changes, and then select **Yes (5)** to confirm the restart of the server.

    ![](images/iaas-image35.png)

    ![](images/iaas-image36.png)

1. Return to the Azure portal and open a new Azure Bastion session to **SQLVM2** with **Username:** demouser@contoso.com and **Password**: Demo!pass123. Launch **SQL Server 2017 Configuration Manager** and repeat steps 21 to 24, mentioned above, to **enable SQL AlwaysOn** and change the **Log On** username. Make sure that you have restarted the SQL service.

1. Return to the Azure portal and open a second Azure Bastion session to **SQLVM2**. This time, use `demouser` as the **username (1)** instead of `demouser@contoso.com` and use **Password (2)**: `Demo!pass123`. Finally, click on **Connect (3)**.
    ![](images/iaas-image37.png)

1. From the **start menu (1)**, search **SQL Server Management Studio 20 (2)** and launch **SQL Server Management Studio (3)**. A new dialog box will open. Verify the following values:

   - Server name: **SQLVM2 (1)**
   - Authentication: **Windows Authentication (2)**
   - User name: **SQLVM2\demouser (3)**
   - Ensure that the **Trust server certificate (4)** is selected and click on **Connect (5)** to sign on to **SQLVM2**. 

    ![](images/iaas-image38.png)

    ![](images/iaas-image39.png)

    > **Note**: The username for your lab should show **SQLVM2\demouser**.
 
1. Moving on, expand **Security (1)** and then **Logins (2)**. You will notice that only `SQLVM2\demouser` **(3)** is listed.

    ![](images/iaas-image40.png)

1. Right-click on **Logins (1)** and then select **New Login... (2)**

    ![](images/iaas-image41.png)

1. In the **Login name,** type **contoso\demouser (1)**, then select **Server Roles (2)**.

    ![](images/iaas-image42.png)

1. Check the box for **sysadmin (1)** and select **OK (2)**.

    ![](images/iaas-image43.png)

1. Return to the Azure portal and open a second Azure Bastion session to **SQLVM1**. This time, use `demouser` as the **username (1)** instead of `demouser@contoso.com` and  use **Password (2)**: `Demo!pass123`. Then click on **Connect (3)**.

   ![](images/iaas-image44.png)

1. Click on **Start (1)**, search **ssms (2)** and launch **SQL Server Management Studio 20 (3)**. A new dialog box will open. Ensure that the **Trust server certificate** is selected and click on **Connect** to sign on to **SQLVM1**. 

     - Server name: **SQLVM1 (1)**
     - Authentication: **Windows Authentication**
     - User name: **SQLVM1\demouser**
     - Ensure that the **Trust server certificate (2)** is selected and click on **Connect (3)** to sign on to **SQLVM1**. 
     
       ![](images/iaas-image38.png)

       ![](images/iaas-image45upd.png)

    > **Note**: The username for your lab should show **SQLVM1\demouser**.
    
1. And then expand **Security (1)** and then **Logins (2)**. You will notice that only `SQLVM1\demouser` **(3)** is listed.

    ![](images/iaas-image46.png)

1. Right-click on **Logins (1)** and then select **New Login... (2)**

     ![](images/iaas-image47.png)

1. In the **Login name,** type **contoso\demouser (1)**, then select **Server Roles (2)**.

    ![](images/iaas-image48.png)

1. Check the box for **sysadmin (1)** and select **OK (2)**. Close the bastion session.

    ![](images/iaas-image43.png)

1. Return to your session with **SQLVM1**. Use the Start menu to launch **Microsoft SQL Server Management Studio 20** and connect to the local instance of SQL Server. (Located in the Microsoft SQL Server Tools folder).

    ![Screenshot of Microsoft SQL Server Management Studio 18 on the Start menu.](images/image172.png "Microsoft SQL Server Management Studio 18")

1. Select the **Trust server certificate** and click on **Connect** to sign on to **SQLVM1**. **Note**: The username for your lab should show **CONTOSO\demouser**.

    ![Screenshot of the Connect to Server dialog box.](images1/E1T3S33.png "Connect to Server dialog box")
    
1. Expand databases and verify that the **ContosoInsurance** is present.  

    > **Note:** Skip on to the step-49, if ContosoInsurance is already present.

    ![.](images/upd-1.png)
    
1. Right-click on **Databases (1)** and select **New Database (2)**.   

    ![.](images/upd-2.png)

1. On the **New Database** window, enter **ContosoInsurance (1)** as the **Database name** and then click on **OK (2)**.

    ![.](images/upd-3.png)
    
1.  Right-click on **ContosoInsurance (1)** and select **Tasks (2)**. Then click on **Back Up... (3)**.

    ![.](images/upd-41.png)

1. On the **Back Up Database - Contosolnsurance** window, click on **OK**.

    ![.](images/upd-5.png)

1. When prompted with **The backup of database 'Contosolnsurance' completed successfully** window, click on **OK**.

    ![.](images/upd-6.png)

1. Click on **New Query**.

    ![.](images/upd-7.png)

1. **Copy and paste (1)** the following query and then click on **Execute (2)**.

    ```
        USE master;
        GO
        GRANT ALTER ANY AVAILABILITY GROUP TO [NT AUTHORITY\SYSTEM]
        GO
        GRANT CONNECT SQL TO [NT AUTHORITY\SYSTEM]
        GO
        GRANT VIEW SERVER STATE TO [NT AUTHORITY\SYSTEM]
        GO
    
    ```    

    ![.](images/upd-8.png)

1. Wait until the query runs successfully.

    ![.](images/upd-9.png)
 

1. Right-click **AlwaysOn High Availability (1)**, then select **New Availability Group Wizard (2)**.

    ![In Object Explorer, AlwaysOn High Availability is selected, and from its right-click menu, New Availability Group Wizard is selected.](images/image174upd.png "SQ Server Management Studio, Object Explorer")

1. Select **Next** on the Wizard.

    ![On the New Availability Group Wizard begin page, Next is selected.](images/p50upd1.png "New Availability Group Wizard ")

1. Provide the name **BCDRAOG (1)** for the **Availability group name**, then select **Next (2)**.

    ![The Specify availability group options form displays the previous availability group name.](images/image176upd.png "Specify availability group options page")

1. Select the **ContosoInsurance Database (1)**, then select **Next (2)**.

    ![The ContosoInsurance database is selected from the user databases list.](images/image177upd.png "Select Databases page")

1. On the **Specify Replicas** screen next to **SQLVM1**, select **Automatic Failover**.

    ![On the Replicas tab, for SQLVM1, the checkbox for Automatic Failover (Up to 3) is selected.](images/image178.png "Specify Replicas screen")

1. Select **Add Replica**.

    ![Screenshot of the Add replica button.](images/image179upd1.png "Add replica button")

1. On the **Connect to Server** dialog box, enter the **server name (1)** of **SQLVM2**, enable **Trust server certificate (2)** check box and select **Connect (2)**. **Note**: The username for your lab should show **CONTOSO\demouser**.

    ![Screenshot of the Connect to Server dialog box for SQLVM2.](images1/E1T3S40upd.png "Connect to Server dialog box")

1. For **SQLVM2**, select **Automatic Failover** and **Availability Mode of Synchronous** commit.

    ![On the Replicas tab, for SQLVM2, the checkbox for Automatic Failover (Up to 3) is selected, and availability mode is set to synchronous commit.](images/image181.png "Specify Replicas Screen")

1. Select **Endpoints** and review those that the wizard has created.

    ![On the Endpoints tab, the three servers are listed.](images1/E1T3S42.png "Specify Endpoints screen")

1. Next, select **Listener**. Then, select the **Create an availability group listener** option.

    ![On the Listener tab, the radio button for Create an availability group listener is selected.](images/image185upd.png "Specify Listener screen")

1. Add the following details:

    - **Listener DNS Name**: BCDRAOG
    - **Port**: 1433
    - **Network Mode**: Static IP

    ![Fields for the Listener details are set to the previously defined settings.](images/image186.png "Listener details")

1. Next, select **Add**.

    ![The Add button is selected beneath an empty subnet table.](images/image187upd.png "Add button")

1. Select the subnet of **10.0.2.0/24** and then add IPv4 **10.0.2.100** and select **OK**. This is the IP address of the internal load balancer that is in front of the **SQLVM1** and **SQLVM2** in the **data** subnet running on the **primary** site.

    ![The Add IP Address dialog box fields are set to the previously defined settings.](images/image188upd.png "Add IP Address dialog box")

1. Select **Next**.

    ![On the Listener tab, the Next button is selected.](images1/E1T3S47.png "Next button")

1. On the **Select Initial Data Synchronization** screen, make sure that **Automatic Seeding** is selected and select **Next**.

    ![On the Select Initial Data Synchronization screen, the radio button for Automatic seeding is selected. The Next button is selected at the bottom of the form.](images/image192upd.png "Select Initial Data Synchronization screen")

1. On the **Validation** screen, you should see all green. Select **Next**.

    ![The Validation screen displays a list of everything it is checking, and the results for each, which all display success. The Next button is selected.](images1/E1T3S49.png "Validation screen")

1. On the **Summary page**, select **Finish**.

    ![On the Summary page, the Finish button is selected.](images/image194upd.png "Summary page")

1. Once the AOG is built, check that each task was successful and select **Close**.

    ![On the New Availability Group Results page, a message says the wizard has completed successfully, and results for all steps is success. The Close button is selected.](images1/E1T3S51.png "New Availability Group Results page")

1. Move back to **SQL Management Studio** on **SQLVM1** and expand the **AlwaysOn High Availability** item in the tree view. Under Availability Groups, expand the **BCDRAOG (Primary)** item.

    ![In SQL Management Studio, Always On High Availability is expanded in the tree view.](images1/E1T3S52.png "SQL Management Studio")

1. Right-click **BCDRAOG (Primary)** and then select **Show Dashboard**. You should see that all the nodes have been added and are now "**green.**"

    ![Screenshot of the BCDRAOG Dashboard indicating the status of all SQL Server VMs as healthy.](images1/E1T3S53.png "BCDRAOG Dashboard")

1. Next, select **Connect** and then **Database Engine** in **SQL Management Studio**.

    ![Connect / Database Engine is selected in Object Explorer.](images/image200upd.png "Object Explorer")

1. Enter **BCDRAOG** as the server name. This will be connected to the listener of the group that you created. **Note**: The username for your lab should show **CONTOSO\demouser**.

    ![In the Connect to Server Dialog box, Server name is BCDRAOG, and the connect button is selected.](images1/E1T3S55upd.png "Connect to Server Dialog box")

1. Once connected to the **BCDRAOG**, you can select **Databases** and will be able to see the database there. Notice that you have no knowledge directly of which server this is running on.

    ![A call out points to ContosoInsurance (Synchronized) in SQL Management Studio.](images/image202upd.png "SQL Management Studio")

1. Move back to **PowerShell ISE** on **SQLVM1**. Open a new file, paste it into the following script, and select the **Play** button. This will update the **Failover cluster** with the IP address of the listener that you created for the AOG.

    ```Powershell
    $ClusterNetworkName = "Cluster Network 1"
    $IPResourceName = "BCDRAOG_10.0.2.100"
    $ILBIP = "10.0.2.100"
    Import-Module FailoverClusters
    Get-ClusterResource $IPResourceName | Set-ClusterParameter -Multiple @{"Address"="$ILBIP";"ProbePort"="59999";"SubnetMask"="255.255.255.255";"Network"="$ClusterNetworkName";"EnableDhcp"=0}
    Stop-ClusterResource -Name $IPResourceName
    Start-ClusterResource -Name "BCDRAOG"
    ```

    ![In the Windows PowerShell ISE window, the play button is selected. The script from the lab guide has been executed.](images1/E1T3S57.png "Windows PowerShell ISE window")

1. Move back to SQL Management Studio and select **Connect** and then **Database Engine**.

    ![In Object Explorer, Connect / Database Engine is selected.](images/image200upd.png "Object Explorer")

1. This time, put the following into the IP address of the internal load balancer of the **Primary** site AOG load balancer: **10.0.2.100**. You again will be able to connect to the server, which is up and running as the master. **Note**: The username for your lab should show **CONTOSO\demouser**.

    ![Fields in the Connect to Server dialog box are set to the previously defined settings.](images1/E1T3S59upd.png "Connect to Server dialog box")

1. Once connected to **10.0.2.100**, you can select **Databases** and will be able to see the database there. Notice that you do not know directly which server this is running on.

    ![A call out points to the Databases folder in Object Explorer.](images1/E1T3S60.png "Object Explorer")

    > **Note:** It could take a minute to connect the first time as this is going through the Azure Internal Load Balancer.

1. Move back to Failover Cluster Manager on **SQLVM1**, and you can review the IP addresses that were added by selecting roles and **BCDRAOG** and viewing the resources. Notice how the **10.0.2.100** is online.

    ![In the Failover Cluster Manager tree view, Roles is selected. Under Roles, BCDRAOG is selected, and details of the role display.](images1/E1T3S61.png "Failover Cluster Manager")

You have now successfully set up the SQL Server VMs to use Always On Availability Groups with a Cloud Witness storage account located in another region.

### Task 4: Configure HA for the Web tier

In this task, you will configure a high-availability web tier. This comprises two web server VMs, which you will locate behind an Azure load balancer. You will also configure the VMs to access the database using the Always On Availability Group endpoint you created earlier.

1.  In the Azure portal, navigate to **WebVM1**, select **Connect** followed by **Bastion**, and connect to the VM using the following credentials:

    - **Username**: `demouser@contoso.com`
    - **Password**: `Demo!pass123`

1.  In **WebVM1**, open Windows Explorer, navigate to **C:\inetpub\wwwroot**, and open the **Web.config** file using Notepad.

    ![notepad.](images1/notepad.png "Failover Cluster Manager")

    > **Note**: If the **Web.config** change does not run, go to **Start**, **Run**, and type **iisreset /restart** from the command line.

1.  In the **Web.config** file, locate the **\<ConnectionStrings\>** element and replace **SQLVM1** with **BCDRAOG** in the data source. Remember to **Save** the file.

    ![Notepad is editing the Web.config file. The data source is updated to BCDRAOG.contoso.com.](images1/E1T4S3.png "Web.config file")

1.  Repeat the above steps to make the same change on **WebVM2**.

1.  Return to the Azure portal and navigate to the **ContosoWebLBPrimary** load balancer blade. Select **Backend pools** and open **BackEndPool1**.

    ![Azure portal showing path to BackEndPool1 on ContosoWebLBPrimary.](images1/E1T4S5upd.png "Backend pool select path")

1.  In the **BackendPool1** blade, select **VNet1 (ContosoRG1)** as the virtual network. Then select **+ Add** and select the two web VMs. Select **Save**.

    ![Azure portal showing WebVM1 and WebVM2 being added to the backend pool.](images1/E1T4S6.1.png "Backend pool VMs")

1.  You will now check that the Contoso sample application is working when accessed through the load balancer. In the Azure portal, navigate to the **ContosoWebLBPrimaryIP** resource. This is the public IP address attached to the web tier load balancer front end. Copy the **DNS name** to the clipboard.

    ![Azure portal showing web load balancer public IP, with DNS name highlighted.](images1/E1T4S7.png "Public IP DNS name")

1.  Open a new browser tab and paste the DNS name. The Contoso Insurance sample app is shown. 

    ![Browser screenshot showing the contoso sample application. The address bar shows the DNS name copied earlier.](images1/E1T4S8.png "Contoso app")

    > **Note:** You will test the HA capabilities later in the lab.

## Summary 

In this exercise, you have deployed High Availability (HA) resources and configured HA for each tier, including the Domain Controller, SQL Server, and Web tiers. This ensured redundancy and fault tolerance across all critical application components.

### You have successfully completed the exercise.
Now, click on **Next** from the lower right corner to move to the next page.

