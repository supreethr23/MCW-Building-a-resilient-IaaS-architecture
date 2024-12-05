## Exercise 4: Validate resiliency

Duration: 90 minutes

In this exercise, you will validate the high availability, disaster recovery, and backup solutions you have implemented in the earlier lab exercises.

### Task 1: Validate High Availability

In this task we will validate high availability for both the Web and SQL tiers.

1.  In the Azure portal, open the **ContosoRG1** resource group. Select the public IP address for the web tier load-balancer, **ContosoWebLBPrimaryIP**. Select the **Overview** tab and copy the DNS name to the clipboard, and navigate to it in a different browser tab.

2.  The Contoso application is shown. Select **Current Policy Offerings** to view the policy list - this shows the database is accessible. As an additional check, edit an existing policy and save your changes, to show that the database is writable.

3.  Open an Azure Bastion session with **SQLVM1** (with username `demouser@contoso.com` and password `Demo!pass123`). Open **SQL Server Management Studio** and connect to **SQLVM1** using Windows Authentication. Locate the BCDRAOG availability group, right-click and select **Show Dashboard**. Note that the dashboard shows **SQLVM1** as the primary replica.

    ![SQL Server Management Studio screenshot showing SQLVM1 as the primary replica.](images1/E4T1S3.png "SQLVM1 as Primary")

4.  Using the Azure portal, stop both **WebVM1** and **SQLVM1**. Wait a minute for the VMs to stop.

5.  Refresh the blade with the Contoso application. The application still works. Confirm again that the database is writable by changing one of the policies.

6.  Open an Azure Bastion session with **SQLVM2** (with username `demouser@contoso.com` and password `Demo!pass123`). Open **SQL Server Management Studio** and connect to **SQLVM2** using Windows Authentication. Locate the BCDRAOG availability group, right-click and select **Show Dashboard**. Note that the dashboard shows **SQLVM2** as the primary replica, and there is a critical warning about **SQLVM1** not being available.

    ![SQL Server Management Studio screenshot showing SQLVM2 as the primary replica, with warnings.](images1/E4T1S6.png "SQLVM2 as Primary")

7.  Restart **WebVM1** and **SQLVM1**. **Wait a full two minutes** for the VMs to start - **this is important**, we don't want to test simultaneous failover of SQLVM1 and SQLVM2 at this stage. Then stop **WebVM2** and **SQLVM2**.

8.  Refresh the blade with the Contoso application. The application still works. Confirm again that the database is writable by changing one of the policies.

9.  Re-open an Azure Bastion session with **SQLVM1** (with username `demouser@contoso.com` and password `Demo!pass123`). Open **SQL Server Management Studio** and connect to **SQLVM1** using Windows Authentication. Locate the BCDRAOG availability group, right-click and select **Show Dashboard**. Note that the dashboard shows **SQLVM1** as the primary replica, and there is a critical warning about **SQLVM2** not being available.

    ![SQL Server Management Studio screenshot showing SQLVM1 as the primary replica, with warnings.](images1/E4T1S9.png "SQLVM1 as Primary")

10. Re-start **SQLVM2** and **WebVM2**.

### Task 2: Validate Disaster Recovery - Failover IaaS region to region

In this task, you will validate failover of the Contoso application from Primary region to Secondary region. The failover is orchestrated by Azure Site Recovery using the recovery plan you configured earlier. It includes failover of both the web tier (creating new Web VMs from the replicated data) and SQL Server tier (failure to the SQLVM3 asynchronous replica). The failover process is fully automated, with custom steps implemented using Azure Automation runbooks triggered by the Recovery Plan.

1.  Using the Azure portal, open the **ContosoRG1** resource group. Navigate to the Front Door resource, locate Frontend Host URL and open it in a new browser tab. Navigate to it to ensure that the application is up and running from the Primary Site.

    ![The Frontend host link is called out.](images1/E4T2S1.png "Frontend host")

    Keep this browser tab open, you will return to it later in the lab.

2.  From a new browser tab, open the Azure portal, then navigate to the **BCDRRSV** Recovery Services Vault located in the **ContosoRG2** resource group.

3.  Select **Recovery Plans (Site Recovery)** in the **Manage** area, then select **BCDRIaaSPlan**.

    ![In the Recovery Services vault blade, BCDRIaaSPlan is selected in the Recovery Plans view.](images1/E4T2S3.png "Recovery Plans")

4. Select **Failover**.

    ![In the BCDRIaaSPlan blade, the Failover button is highlighted.](images1/E4T2S4.png "BCDRIaaSPlan blade")

   >**Note:** If u encounter an error then follow step 5 to step 8.

5. Navigate back on Failover, select **I understand the risk, Skip test failover**.

    ![A warning displays that no test failover has been done in the past 180 days, and recommends that you do one before a failover. At the bottom, the I understand and skip test failover checkbox is selected.](images1/E4T2S8.png "Failover warning")

6. Review the Failover direction. Notice that **From** is the **Primary** site, and **To** is the **Secondary** site. Select **OK**.

    ![Call outs in the Failover blade point to the From and To fields.](images1/E4T2S9upd.png "Failover blade")
  
7. If you face an error while performing the Failover then go to **Replicated items** under Protected items and select **WebVM1** and then click on **Cleanup test  failover**.

      ![](images/updated14.png "Failover blade")
      
8. On the Test failover cleanup page, Enter notes as **Test Cleanup** and select the check box and click on **Ok**.

      ![](images/updated13.png "Failover blade")
      
9. Performing the same step from step 5 to 8 as for **WebVM2**.

5. Navigate back on Failover, select **I understand the risk, Skip test failover**.

    ![A warning displays that no test failover has been done in the past 180 days, and recommends that you do one before a failover. At the bottom, the I understand and skip test failover checkbox is selected.](images1/E4T2S8.png "Failover warning")

6. Review the Failover direction. Notice that **From** is the **Primary** site, and **To** is the **Secondary** site. Select **OK**.

    ![Call outs in the Failover blade point to the From and To fields.](images1/E4T2S9upd.png "Failover blade")

7. After the Failover is initiated, close the Failover blade and navigate to **Site Recovery Jobs**. Select the **Failover** job to monitor the progress.

    ![Failover is selected in the Site Recover jobs blade.](images1/E4T2S10.png "Site Recover jobs blade")

8. You can monitor the progress of the Failover from this panel.

    ![Output is selected on the Job blade, and information displays in the Output blade.](images1/E4T2S11.png "Job and Output blades")

    > **Note:** Do not make any changes to your VMs in the Azure portal during this process. Allow ASR to take the actions and wait for the failover notification before moving on to the next step. You can open another portal view in a new browser tab and review the output of the Azure Automation Jobs, by opening the jobs and selecting Output.
    >
    > ![Screenshot of the ASRSQLFailover Azure Automation runbook job. The status of Zero warnings and zero errors is highlighted.](images1/E4T2S11.png "Automation Job status")

9.  Once the Failover job has finished, it should show as *Successful* for all tasks. This may take more than 15 minutes.

    ![Under the Site Recovery Job, the status for the job steps all show as successful.](images1/E4T2S12.png "Job status")

10. Select **Resource groups** and select **ContosoRG1**. Open **WebVM1** and notice that it currently shows as **Status: Stopped (deallocated).** This shows that failover automation has stopped the VMs at the **Primary** site.

    ![A call out points to the Status of Stopped (deallocated) in the Virtual machine blade. The VM location is Central US.](images1/E4T2S13.png "Virtual machine blade")

    > **Note:** Do not select Start! The VM will be restarted automatically by ASR during failback.

11. Move back to the Resource group and select the **ContosoWebLBPrimaryIP** Public IP address. Copy the DNS name and paste it into a new browser tab. The website will be unreachable at the Primary location, since the Web VMs at this location have been stopped by ASR during failover.

12. In the Azure portal, move to the **ContosoRG2** resource group. Locate the **WebVM1** in the resource group and select to open. Notice that **WebVM1** is running in the **Secondary** site.

    ![In the Virtual Machine blade, a call out points to the status of WebVM1, which is now running.](images1/E4T2S15.png "Virtual Machine blade")

13. Move back to the **ContosoRG2** resource group and select the **ContosoWebLBSecondaryIP** Public IP address. Copy the DNS name and paste it into a new browser tab. The Contoso application is now responding from the **Secondary** site. Make sure to select the current Policy Offerings to ensure connectivity to the SQL Always-On group that was also failed over in the background.

14. Go back to the browser tab with the Contoso application open at the Front Door URL and refresh the page. The site should load quickly from the DR site. Users accessing the service via Front Door are automatically routed to the active site, ensuring seamless access despite the failover. While there may be some downtime during the failover process, once the site is back online, the user experience will remain the same as when it was running on the **Primary** site. If the page does not load immediately, wait for a few moments and try refreshing again.

    ![The Contoso Insurance PolicyConnect webpage displays. The URL is from Azure Front Door.](images1/E4T2S17.png "Contoso Insurance PolicyConnect webpage")

    > **Optional task**: you can log in to **SQLVM3** and open the SQL Management Studio to review the Failed over **BCDRAOG**. You will see that **SQLVM3**, which is running in the **Secondary** site is now the Primary Replica.

15. Now that you have successfully tested failover, you need to configure ASR for failback. Move back to the **BCDRSRV** Recovery Service Vault using the Azure portal. Select **Recovery Plans** on the ASR dashboard. The **BCDRIaaSPlan** will show as **Failover completed.** 

    ![Recovery Plans list, with the 'Failover Completed' status of the BCDRIaaSPlan highlighted.](images1/E4T2S18.png "Recovery Plans")

16. Select the BCDRIaasPlan plan. Notice that now two (2) VMs are now shown in the **Target** tile.

    ![In the Recovery blade, the Target tile has the number 2.](images1/E4T2S19.png "Recovery plan blade")

17. Select **Re-protect**.

    ![Recovery Plan blade with Re-protect button highlighted.](images1/E4T2S20.png "Re-protect button")

18. On the **Re-protect** screen review the configuration and then select **OK**.

    ![Screenshot of the Re-protect blade.](images1/E4T2S21.png "Re-protect blade")

19. The portal will submit a deployment. This process will take up to 30 minutes to commit the failover and then synchronize WebVM1 and WebVM2 with the Recovery Services Vault. Once this process is complete, you will be able to failback to the primary site.

    > **Note:** You need to wait for the re-protect process to complete before continuing with the failback. You can check the status of the Re-protect using the Site Recovery Jobs area of the BCDRSRV.
    >
    > ![In the Recovery blade, Re-protect has a status of In progress for two jobs, one for WebVM1 and one for WebVM2.](images1/E4T2S22.png "Site Recovery jobs")
    >
    > Once the jobs are completed, move to the **Replicated items** blade and wait for the **Status** to show as **Protected**. This status shows the data synchronization is complete and the Web VMs are ready to failback.
    >
    > ![In the Replicated items, WebVM1 and WebVM2 have status 'Protected'.](images1/E4T2S22.1.png "Replicated items")

### Task 3: Validate Disaster Recovery - Failback IaaS region to region

In this task, you will failback the Contoso application from the DR site in Secondary Site back to the Primary site.

1.  Still in the **BCDRRSV** Recovery Services vault, select **Recovery Plans** and re-open the **BCDRIaaSPlan**. Notice that the VMs are still at the Target since they are failed over to the secondary site.

2.  Select **Failover**. At the warning about No Test Failover, select **I understand the risk, Skip test failover**. Notice that **From** is the **Secondary** site and **To** is the **Primary** site. Select **OK**.

    ![Screenshot of the Failover blade, from East US 2 to Central US.](images1/E4T2S9upd.png "Failover (failback)")

3.  After the Failover is initiated close the blade and select **Site Recovery Jobs**, then select the **Failover** job to monitor the progress. Once the job has finished, it should show as successful for all tasks.

    ![](images1/E4T3S3.png "Job status")

4.  Confirm that the Contoso application is once again accessible via the **ContosoWebLBPrimaryIP** public IP address, and is **not** available at the **ContosoWebLBSecondaryIP** address. This test shows it has been returned to the primary site. Open the **Current Policy Offerings** and edit a policy, to confirm database access. 

    > **Note:** If you get a "Our services aren't available right now" error (or a 404-type error) accessing the web application, verify that you are utilizing the **ContosoWebLBPrimaryIP**.  If it does not come up within ~10 minutes, verify that the backend system is responding.

5.  Confirm also that the Contoso application is also available via the Front Door URL.

6.  Now, that you have successfully failed back, you need to prep ASR for the Failover again. Move back to the **BCDRSRV** Recovery Service Vault using the Azure portal. Select Recovery Plans and open the **BCDRIaaSPlan**.

7.  Notice that now 2 VMs are shown in the **Source**. Select **Re-protect**, review the configuration and select **OK**.

    ![The recovery plan shows 2 VMs in the Source and 0 in the target. The 'Re-protect' button is highlighted.](images1/E4T3S7.png "BCDRIaaSPlan")

8.  As previously, the portal will submit a deployment. This process will take some time. You can proceed with the lab without waiting.

9.  Next, you need to reset the SQL Always On Availability Group environment to ensure a proper failover. Use Azure Bastion to connect to **SQLVM1** with username `demouser@contoso.com` and password `Demo!pass123`.

10. Once connected to **SQLVM1** open SQL Server Management Studio and Connect to **SQLVM1**. Expand the **Always On Availability Group**s and then right-click on **BCDRAOG** and then select **Show Dashboard**.

11. Notice that all the Replica partners are now Synchronous Commit with Automatic Failover Mode. You need to manually reset **SQLVM3** to be **Asynchronous** with **Manual Failover**.

    ![The Availability group dashboard displays with SQLVM3 and its properties called out.](images/image400.png "Availability group dashboard")

12. Right-click the **BCDRAOG** and select **Properties**.

    ![In Object Explorer, the right-click menu for BCDRAOG displays with Properties selected.](images/image401.png "Object Explorer")

13. Change **SQLVM3** to **Asynchronous** and **Manual Failover** and select **OK**.

    ![In the Availability Group Properties window, under Availability Replicas, the SQLVM3 server role is secondary, availability mode is asynchronous commit, and failover mode is manual.](images/image402.png "Availability Group Properties window")

14. Show the Availability Group Dashboard again. Notice that they change has been made and that the AOG is now reset.

    ![The Availability group dashboard displays, with SQLVM3 and its properties called out.](images/image403.png "Availability group dashboard")

    > **Note:** This task could have been done using the Azure Automation script during Failback, but most DBAs would prefer a clean failback and then do this manually once they are comfortable with the failback.

### Task 4: Validate VM Backup

In this task, you will validate the backup for the Contoso application WebVMs. You will do this by removing several image files from **WebVM1**, breaking the Contoso application. You will then restore the VM from backup. 

1.  From the Azure portal, locate and shut down **WebVM2**. This forces all traffic to be served by **WebVM1**, which making the backup/restore verification easier.
   
2.  Navigate to **WebVM1** and connect to the VM using Azure Bastion, using username `demouser@contoso.com` and password `Demo!pass123`.

3.  Open Windows Explorer and navigate to the `C:\inetpub\wwwroot\Content` folder. Select the three `.PNG` files and delete them.

    ![Windows Explorer is used to delete PNG files from the Contoso application.](images1/E4T4S3.png "Delete PNG files")

4.  In the Azure portal, locate the **ContosoWebLBPrimaryIP** public IP address in **ContosoRG1**. Copy the DNS name and open it in a new browser tab. Hold down `CTRL` and refresh the browser, to reload the page without using your local browser cache. The Contoso application should be shown with images missing.

    ![Browser screenshot showing the Contoso application with missing images highlighted.](images1/E4T4S4.png "Contoso application with missing images")

5.  To restore WebVM1 from backup, Azure Backup requires that a 'staging' storage account be available. To create this account, in the Azure portal select **+ Create a resource**, then search for and select **Storage account**. Select **Create**.

6.  Complete the 'Create storage account' form as follows, then select **Review** followed by **Create**.

    -   **Resource group:** ContosoRG1
    -   **Storage account name:** Unique name starting with `backupstaging`.
    -   **Location:** <inject key="Region" enableCopy="false" /> *(this is your primary region)*
    -   **Performance:** Standard
    -   **Replication:** Locally-redundant storage (LRS)

    ![Screenshot showing the 'Create storage account' blade in the Azure portal.](images1/ex4-task4-step6.png "Create storage account")

7.  Before restoring a VM, the existing VM must be shut down. Use the Azure portal to shut down **WebVM1**.

    > **Note:** since WebVM2 is also shut down, this will break the Contoso application. In a real-world scenario, you would keep WebVM2 running while restoring WebVM1.

8.  In the Azure portal, navigate to the **BackupRSV** Recovery Services Vault. Under 'Protected Items', select **Backup items**, then select **Azure Virtual Machine**.

    ![Screenshot showing the Recovery Services Vault, with the links to the Azure Virtual Machine backup item highlighted.](images1/E4T4S8.png "Backup items")

9.  On the Backup items page, select **View details** for **WebVM1**. On the **WebVM1** page, select **RestoreVM**.

    ![Screenshot showing the WebVM1 backup status page, with the 'Restore VM' button highlighted.](images1/E4T4S9.png "Restore VM button")

10. Complete the Restore Virtual Machine page as follows, then select **Restore**.

    -   **Restore point:** Select the most recent restore point.
    -   **Restore Configuration:** Replace existing
    -   **Staging Location**: Choose the storage account you created earlier, starting with `backupstaging`.

    ![Screenshot showing settings to restore WebVM1, replacing the existing VM.](images1/E4T4S10.png "Restore VM options")

11. In the **BackupRSV** vault, navigate to the **Backup Jobs** view. Note that two new jobs are shown as 'In progress', one to take a backup of the VM and a second to restore the VM.

    ![Screenshot showing both backup and restore jobs for WebVM1.](images1/E4T4S11.png "Restore VM Backup Jobs")

12. It will take several minutes for the VM to be restored. Wait for the restore to complete before proceeding with the lab.

13. Once the restore operation is complete, navigate to the **WebVM1** blade in the Azure portal, and **Start** the VM.

14. Wait for the VM to start, then return to your browser tab showing the Contoso application with missing images. Hold down `CTRL` and select **Refresh** to reload the page. The application is displayed with the images restored, showing the restore from backup has been successful. (As an optional step, you can also open a Bastion connection to the VM and check the deleted .PNG files have been restored.)

15. Start **WebVM2**.

### Task 5: Validate SQL Backup

In this task, you will validate the ability to restore the Contoso application database from Azure Backup.

1.  In the Azure portal, navigate to the **BackupRSV** in **ContosoRG1**. Under 'Protected items', select **Backup items**, then select **SQL in Azure VM**.

    ![Screenshot showing the path to the SQL in Azure VMs in backup items in the Recovery Services Vault.](images1/E4T5S1.png "Backup items")

2.  From the backup items list, select **View details** for the **contosoinsurance** database.

3.  From the **contosoinsurance** blade, select **Restore**.
    
    ![Screenshot showing the restore button for the contosoinsurance database backup.](images1/E4T5S3.png "Restore button")

4.  Review the default settings on the **Restore** blade. By default, the backup will be restored to a new database alongside the existing database on SQLVM1.

    ![Screenshot showing the settings to restore a SQL database from Azure Backup.](images1/E4T5S4.png "Restore database settings")

    > **Note:** For an Always On Availability Group backup, the option to overwrite the existing database is not available. You must restore to a parallel location.

5.  Select the option to choose your Restore Point. On the 'Select restore point' blade, explore the restore options. Note how the log-based option offers a point-in-time restore, whereas the full & differential option provides backup based on the backup schedule.

    Choose any restore point and select **OK**.

    ![Screenshot showing the options to select a restore point based on logs.](images1/ex4-task5-step5a.png "Select restore point - Logs")

    ![Screenshot showing the options to select a restore point based on scheduled backups.](images1/ex4-task5-step5b.png "Select restore point - Full & Differential")

6.  Under 'Advanced Configuration', select **Configure**. Review the settings but don't change anything. Select **OK** to accept the default configuration
   
7.  Select **OK** to start the restore process.
   
8.  Navigate to the **Backup Jobs** view. The ContosoInsurance job is 'In progress'. Use the **Refresh** button to monitor the progress and wait for the job to complete.

    ![Screenshot showing the list of backup jobs with the database restore highlighted.](images1/E4T5S8.png "Database restore backup job")

9.  Navigate to **SQLVM1** and connect to the VM using Azure Bastion, using username `demouser@contoso.com` and password `Demo!pass123`.

10. On SQLVM1, open **SQL Server Management Studio** and connect to SQLVM1.

11. Note that the restored database is present on the server alongside the production database.

    ![Screenshot showing the restored database in SQL Server Management Studio.](images1/E4T5S11.png "Restored database")

    > **Note:** You can now either copy data from the restored database to the production database, or add this database to the Always On Availability Group and switch the Web tier to use the restored database.
