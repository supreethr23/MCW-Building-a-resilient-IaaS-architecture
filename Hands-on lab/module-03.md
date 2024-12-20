# Exercise 3: Enable Backup for the Contoso Application

### Estimated Duration: 90 Minutes

In this exercise, you will use Azure Backup to enable backup for the Contoso application. You will configure a backup for the web tier VMs and the SQL Server database.

### Objectives
In this exercise, you will complete the following tasks:
   - **Task 1:** Create the Azure Backup Resources
   - **Task 2:** Enable Backup for the Web Tier
   - **Task 3:** Enable Backup for the SQL Server Tier

### Task 1: Create the Azure Backup Resources

In this task, you will create a vault in the primary region for Azure Backup.

1. On the Azure portal, search **(1)** and select **Recovery Services vaults (2)**, then click on **Create**.

    ![Screenshot of the Backup and Site Recovery Screen with the Create button selected.](images1/E3T1S1upd.png "Backup and Site Recovery Screen Create Button")

1.  Complete the **Recovery Services vaults** blade using the following inputs, then click on **Review + create (4)** and **Create**:

    - **Resource Group**: ContosoRG1 **(1)**
    - **Name**: BackupRSV<inject key="DeploymentID" enableCopy="false"/> **(2)**
    - **Location**: <inject key="Region" enableCopy="false" /> *(Primary Region)* **(3)**

    ![Azure portal screenshot showing the Create Recovery Services Vault blade, with the settings filled in as described.](images1/E3T1S2.png "Create Recovery Services Vault")

1. Once the deployment is complete, navigate to the **BackupRSV | Properties <inject key="DeploymentID" enableCopy="false"/>** resource page. Select **Properties (1)** and **Backup Configuration (2)**.

    ![Azure portal screenshot showing the properties blade of the Recovery Services Vault.](images1/E3T1S3upd.png "Recovery Services Vault properties")

1.  Under **Backup Configuration**, select **Update**. In the **Backup Configuration** blade, choose **Geo-redundant (1)** as the **Storage replication type** and set the **Cross Region Restore** option to **Enabled (2)**. Then **Apply (3)** your changes and close the **Backup Configuration** panel.

    ![Azure portal screenshot showing the backup properties blade of the Recovery Services Vault.](images1/E3T1S4upd1.png "Recovery Services Vault backup properties")

    > **Note:** This enables backups from the primary site to be restored to the DR site if required.

1.  On the **BackupRSV | Properties**<inject key="DeploymentID" enableCopy="false"/> blade, select **Update**. For the **Security and soft delete settings** page, **uncheck** the **Enable soft delete for cloud workloads (1)** checkbox and select **Enable soft delete and security settings for hybrid workloads (2)**. Now, **Update (3)** your changes and close the **Security Settings** panel.

    ![Azure portal screenshot showing the security properties blade of the Recovery Services Vault.](images1/ex3-task1-step5upd.png "Recovery Services Vault security properties")

    > **Note:** In a production environment, you should leave **Soft Delete** enabled. However, it is better to turn off this feature for this lab since leaving it enabled makes cleaning up your lab resources more challenging once the lab is complete.

### Task 2: Enable Backup for the Web Tier

You will configure Azure Backup for the web tier virtual machines in this task. Of course, if the web VMs are stateless, backup  may not be required so long as the VM image and/or application installation are protected.

1.  On the **BackupRSV | Backup<inject key="DeploymentID" enableCopy="false"/>** **Recovery Services vault** blade, under **Getting Started**, select **Backup (1)**. Under **Where is your workload running?** select **Azure (2)**. Under **What do you want to back up?** select **Virtual machine (3)**. Then, choose **Backup (4)**.

    ![Azure portal screenshot showing the Getting Started - Backup blade of the Azure Portal, with Azure VMs selected.](images1/E3T2S1.png "Backup VMs")

1.  On the **Configure Backup** page, select **Standard**, and click on **Create a new policy**. Fill in the **Create Policy** blade as follows:

    - **Policy name**: `WebVMPolicy` **(1)**
    - **Backup schedule**: Daily, 9 pm, UTC **(2)**
    - **Retain instant recovery snapshots for**: 2 day(s) **(3)**
    - **Retention of daily backup point**: Enabled, 180 days **(4)**
    - **Retention of weekly backup point**: Enabled, Sunday, 12 weeks **(5)**
    - **Retention of monthly backup point**: Enabled, first Sunday, 24 months **(6)**
    - **Retention of yearly backup point**: Enabled, day-based, January 1, 5 years **(7)**
    - **Azure Backup Resource Group**: ContosoBackupRG **(8)**

    When finished, select **OK (9).**

    ![Azure portal screenshot showing the Backup Policy settings, completed as described.](images1/E3T2S2upd.png "Backup Policy")

1.  On the **Backup** blade, click on **Add (1)** under **Virtual Machines**. Select **WebVM1** and **WebVM2 (2)** virtual machines, then **OK (3)**.

    ![Azure portal screenshot showing the steps to add VMs to the backup.](images1/E3T2S3.png "Add VMs")

1.  Select **Enable Backup** and wait for the deployment to complete.

    ![Azure portal notification showing the VM backup deployment is complete.](images1/E3T2S4.png "Backup deployment complete")

1.  On the **BackupRSV | Back up items <inject key="DeploymentID" enableCopy="false"/>** **Recovery Services vault** blade, under **Protected items**, select **Backup items**. The blade should show 2 Azure VMs as protected.

    ![Azure portal screenshot showing how many protected items of various types are enabled. There are 2 Azure VMs protected.](images1/E3T2S5.png "Backup items")

1.  Select **Azure Virtual Machine**. The **Backup Items (Azure Virtual Machine)** blade will load, listing **WebVM1** and **WebVM2**. In both cases, the **Last Backup Status** is: **'Warning (Initial backup pending)**.

    ![Azure portal screenshot showing WebVM1 and WebVM2 listed for backup, with initial backup pending.](images1/E3T2S6.png "Backup items (Azure Virtual Machine)")

1.  Select **View details** for **WebVM1** to open the **WebVM1 Backup Item** status blade. Select **Backup now**, continue with the default backup retention, and click **OK**.

    ![Azure portal screenshot showing the WebVM1 backup status blade, with the 'Backup now' button highlighted.](images1/E3T2S7.png "Backup now")

    ![Azure portal screenshot the backup retention period for the on-demand backup.](images1/E3T2S7.1.png "Backup now - retention")

    >**Note:** The backup policy created earlier determines the retention period for scheduled backups. For on-demand backups, the retention period is specified separately.

1.  Close the **WebVM1 Backup Item** status blade. Then, repeat the above-mentioned steps to trigger an on-demand backup for **WebVM2**.

1.  On the **BackupRSV<inject key="DeploymentID" enableCopy="false"/> Recovery Services vault** blade, under **Monitoring**, select **Backup Jobs** to load the **Backup Jobs** blade. This shows the current **status** of each backup job. The blade should show two **completed** jobs (configuring backup for WebVM1 and WebVM2) and two **in-progress** jobs (backup for WebVM1 and WebVM2).

    ![Azure portal screenshot showing the backup jobs.](images1/E3T2S9.png "Backup Jobs")

1.  Select **View Details** for **WebVM1** to open the backup job view. You will get a detailed status of the tasks within the backup job.

      ![Azure portal screenshot showing the WebVM1 backup job detailed status. The 'Take snapshot' task is 'In progress' and the 'Transfer data to vault' task is 'Not started'.](images1/E3T2S10.png "Backup Job - WebVM1")

      > **Note**: To restore from a backup, it suffices that the **Take Snapshot** task is complete. Transferring the data to the vault does not need to be complete since recent backups can be restored from the snapshot.

   You can proceed to the next task without waiting for the backup jobs to complete.


### Task 3: Enable Backup for the SQL Server Tier

In this task, you will configure a backup for the SQL Server database.

Before enabling Azure Backup, you will register the SQL Server VMs with the SQL VM resource provider. This resource provider installs the **SqlIaaSExtension** onto the virtual machine. Azure Backup uses this extension to configure the `NT SERVICE\AzureWLBackupPluginSvc` account with the necessary permissions to discover databases on the virtual machine.

1. In a new browser tab, navigate to **[Cloud Shell](https://portal.azure.com/#cloudshell/)** and open a **PowerShell** session.

1. Unless you have done so, you must register your Azure subscription to use the `Microsoft.SqlVirtualMachine` resource provider. In the Cloud Shell window, execute the following command:

    ```PowerShell
    Register-AzResourceProvider -ProviderNamespace Microsoft.SqlVirtualMachine
    ```
    ![Azure Cloud Shell screenshot showing the Microsoft.SqlVirtualMachine resource provider registration. The status is 'Registering'.](images/bk-sql-rp1a.png "Register resource provider")

    > **Note:** It may take several minutes to register the resource provider. Wait until the registration is complete before proceeding to the next step. You can check the registration status using `Get-AzResourceProvider -ProviderNamespace Microsoft.SqlVirtualMachine`.


1. Register **SQLVM1** with the resource provider by executing the following command in the Cloud Shell window. Ensure that **-Location** matches the location where SQLVM1 is deployed.

    ```PowerShell
    New-AzSqlVM -Name 'SQLVM1' -ResourceGroupName 'ContosoRG1' -SqlManagementType Full -Location '[location]' -LicenseType PAYG
    ```

    ![Azure Cloud Shell screenshot showing the SQL Virtual Machine resource being create for SQLVM1.](images/bk-sql-rp2.png "Register resource provider")
    
    > **Note:** Make sure you replace [location] with the ContosoRG1 resource group location.

    > **Note:** This will register the resource provider using the `Full` management mode. This may cause the SQL service to restart, impacting production applications. To avoid this restart in production environments, you can alternatively register the resource provider in `LightWeight` mode and upgrade later during a scheduled maintenance window.

1. Register **SQLVM2** and **SQLVM3** with the resource provider using the following commands. Ensure you specify the correct locations.

    ```PowerShell
    New-AzSqlVM -Name 'SQLVM2' -ResourceGroupName 'ContosoRG1' -SqlManagementType Full -Location '[location1]' -LicenseType PAYG
    New-AzSqlVM -Name 'SQLVM3' -ResourceGroupName 'ContosoRG2' -SqlManagementType Full -Location '[location2]' -LicenseType PAYG
    ```
    
    > **Note:** Make sure you replace [location1] with the ContosoRG1 resource group's location and [location2] with the ContosoRG2 resource group's location.
    
    > **Note:** This lab uses a 'Developer' tier license for SQL Server. When using SQL Server in production at the 'Standard' or 'Enterprise' tier, you can specify `DR` as the license type for failover servers (each full-price server includes a license for 1 DR server). This reduces your licensing cost significantly. Check the SQL Server licensing documentation for complete details.

1. In the Azure portal, navigate to the **ContosoRG1** resource group. You will find that besides SQLVM1 and SQLVM2 virtual machines, there are now parallel SQLVM1 and SQLVM2 resources of type **SQL virtual machine** added. These additional resources provide extra management capabilities for SQL Server in Azure virtual machines. 

    ![Azure portal screenshot showing the SQLVM1 and SQLVM2 SQL virtual machine resources.](images1/E3T3S5.png "SQL virtual machine resources")

1. Select the **SQLVM1** virtual machine (the standard VM resource, not the SQL virtual machine resource). Then select **Extensions + applications (1)**. Note that the **SqlIaaSExtension (2)** has been installed on the virtual machine. You can now configure Azure Backup for virtual machines with the SQL virtual machine resources created and the SQL IaaS extension installed.

    ![Azure portal screenshot showing the SqlIaaSExtension has been deployed to SQLVM1.](images1/E3T3S6upd1.png "SqlIaaSExtension")

1. In the Azure portal, navigate to the **BackupRSV | Backup** **Recovery Services Vault** resource in **ContosoRG1**. Under **Getting started,** select **Backup (1)**. Under **Where is your workload running?** select **Azure (2)**. Under **What do you want to back up?** select **SQL Server in Azure VM (3)**. Then click on **Start Discovery (4)**.

   ![Azure portal screenshot showing the Getting Started - Backup blade of the Azure Portal, with 'SQL Server in Azure VM' selected.](images1/E3T3S7.png "Backup SQL Server in Azure VM")

1. In the **Select Virtual Machines** blade, select **SQLVM1** and **SQLVM2**, then click on **Discover DBs**.

    ![Azure portal screenshot showing the 'Select Virtual Machines' step of enabling backup for SQL Server in Azure VMs. SQLVM1 and SQLVM2 are selected.](images1/E3T3S8.png "Select VMs for SQL Server backup")

1. This will trigger a deployment. Wait for the deployment to complete (this may take several minutes).

    ![Azure portal screenshot showing the 'deployment succeeded' notification.](images1/E3T3S9.png "Success notification")

1. On the **BackupRSV | Backup** <inject key="DeploymentID" enableCopy="false"/> blade, select **Configure Backup**. 

    ![Azure portal screenshot showing the Backup 'Getting Started' settings in the Recovery Services Vault, with 'Configure Backup' highlighted.](images1/E3T3S10.png "Configure backup button")

1. On the **Configure Backup** blade, select **Add**.

    ![Azure portal screenshot showing the Backup 'Backup' settings for the SQL backup, with 'Add' highlighted.](images1/E3T3S11.png "Add button")

1. Select the check box next to `BCDRAOG\BCDRAOG` to show the databases on the **Select items to backup** blade. Note that the **ContosoInsurance** database is listed. Change the **AutoProtect** setting for **BCDRAOG** to **ON**, then select **OK**.

    ![Azure portal screenshot showing available databases to backup. For the BCDRAOG Always On Availability Group, AutoProtect is set to 'ON'.](images1/E3T3S12.png "Select items to backup")

    > **Note:** Using AutoProtect backups the current and future databases on this Always On Availability Group.

    > **Note:** You may also want to backup system databases on each SQL server.

1. On the **Configure Backup** blade, note that **BCDRAOG\BCDRAOG** is now listed for backup. Leave the policy as the default `HourlyLogBackup` policy. Select **Enable backup** and wait for the deployment to complete.

    ![Azure portal screenshot showing the BCDRAOG database listed for backup, and the HourlyLogBackup settings. The 'Enable Backup' button is highlighted.](images1/E3T3S13.png "Enable Backup button")

1. On the **BackupRSV | Backup Jobs <inject key="DeploymentID" enableCopy="false"/>** **Recovery Service vault**, navigate to the **Backup Jobs** view. You should see a backup configuration job in progress for the **ContosoInsurance** database. (If this job does not show immediately, wait a minute and select **Refresh**.)

    ![Azure portal screenshot showing the backup configuration job for the ContosoInsurance database.](images1/E3T3S14.png "Backup configuration job")

1.  Wait for the backup configuration job to complete. Use the **Refresh** button to monitor progress. The configuration job will take several minutes.

1. Select **Backup items**, then select **SQL in Azure VM**.

    ![Screenshot showing the path to the SQL in Azure VMs in backup items in the Recovery Services Vault.](images1/build7.png "Backup items")

1. From the backup items list, note that the **contosoinsurance** database has a status of **Warning (Initial backup pending)**.

    ![Azure portal screenshot showing the backup status for the contosoinsurance database.](images1/E3T3S17.png "Backup status")

1. Select **View details** on the **contosoinsurance** database and select **Backup now.**

      ![Azure portal screenshot showing the backup now button for the contosoinsurance database.](images1/E3T3S18.png "Backup now")

1.  Review the default backup settings, then select **OK** to start the backup.

      ![Azure portal screenshot showing the backup settings for the contosoinsurance database.](images/EX3-T3-S19.png "Backup settings")

1. Once the backup process has started, you can monitor progress from the **Backup Job** pane.

    ![Azure portal screenshot showing the Backup Job for the contosoinsurance database.](images1/E3T3S20.png "Database Backup Job")

    > **Note:** You can continue to the next step in the lab without waiting for the backup job to complete.

   > **Congratulations** on completing the task! Now, it is time to validate it. Here are the steps:
   > - Click on the **Validate** button for the corresponding task. You can proceed to the next task if you receive a success message. 
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at **cloudlabs-support@spektrasystems.com**. We are available 24/7 to help.
   <validation step="7098dae2-eaf0-4683-b0d8-171c745b9f81" />

## Summary 

In this exercise, you created Azure Backup resources and enabled backup for the Web and SQL Server tiers, ensuring critical application components' data protection and recovery capabilities.

### You have successfully completed the exercise.
Click **Next** from the lower right corner to move to the next page.
