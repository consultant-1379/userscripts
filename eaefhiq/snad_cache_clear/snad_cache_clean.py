#!/usr/bin/python
'''
import subprocess
(out,err)=subprocess.Popen(['mkdir','-p','/var/tmp/FTPServices_bk']).communicate()
if err:
    print "Cannot create the folder /var/tmp/FTPServices_bk. the backup cannot be made for FTP services"
else:
    (out,err)=subprocess.Popen(['cp','/var/opt/ericsson/arne/FTPServices/','/var/tmp/FTPServices_bk']).communicate()
    if err:
        print 'backup failed!'
'''

import distutils.core
import sys
import os
import subprocess



def run_progress(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    while True:
        line = p.stdout.readline()
        print line
        if line == '' and p.poll() != None:
            break

'''Prerequisite: Before starting this procedure please Note that all FTP services will be deleted 
so you need to make sure you have all FTP services xml files backedup so you can restore the FTP services.
The FTP services xmls files are located in /var/opt/ericsson/arne/FTPServices.
Also run the following cmd and save the results so it makes it easier to restore the FTP services:
/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s ONRM_CS -ns masterservice lt FtpService'''
if not distutils.dir_util.copy_tree('/var/opt/ericsson/arne/FTPServices/', '/var/tmp/FTPServices_bk'):
    sys.exit('backup failed!')

(out, err) = subprocess.Popen(["/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest", "-s", "ONRM_CS" , "-ns" , "masterservice" , "lt" , "FtpService"], stdout=subprocess.PIPE).communicate()
if err:
    sys.exit('backup failed!')
else:
    f=open("/var/tmp/FTPServices_bk/FtpService.bk",'w')
    f.write(out)
    f.close()
    
    

''' 1. Delete the ONRM_CS DB:'''
(out, err) = subprocess.Popen(['su', 'nmsadm', '-c', '/opt/versant/ODBMS/bin/removedb -f -rmdir ONRM_CS'], stdout=subprocess.PIPE).communicate()
'''
if err:
    sys.exit('remove DB failed')
'''

''' 2. Verify the ONRM DB was removed'''
(out, err) = subprocess.Popen(['/opt/versant/ODBMS/bin/dblist'], stdout=subprocess.PIPE).communicate()
if "ONRM" in str(out):
    sys.exit('ONRM_CS cannot be removed')


'''3. Verify the ONRM Directory was removed'''
(out, err) = subprocess.Popen(['ls', '/export/versant/db/'], stdout=subprocess.PIPE).communicate()
if "ONRM" in str(out):
    sys.exit('ONRM_CS cannot be removed')


'''4. Offline all MCs before proceeding with the next steps'''
# (out,err)=subprocess.Popen(['smtool','-outp','-all','-reason=planned','-reasontext="planned for database clean up"'],stdout=subprocess.PIPE).communicate()
(out, err) = subprocess.Popen(['su', 'nmsadm', '-c', 'smtool -stop -all -reason=planned -reasontext="planned for database clean up"'], stdout=subprocess.PIPE).communicate()
if err:
    sys.exit('outp all services are failed.')
run_progress('su nmsadm -c "smtool -p"')
print 'All services are offline.'


'''5. Recreate the ONRM DB'''
(out, err) = subprocess.Popen(['/opt/ericsson/fwSysConf/bin/createDb.sh'], stdout=subprocess.PIPE).communicate()
if not err:
    '''6. Verify the ONRM Directory was re created'''
    (out, err) = subprocess.Popen(['ls', '/export/versant/db/'], stdout=subprocess.PIPE).communicate()
    if "ONRM_CS" in str(out):
            print 'ONRM_CS DB has been created.'
else:
    sys.exit('ONRM_CS cannot be created')


'''7. Online ONRM, ARNE, MAF and NodeSYnchServer'''
(out, err) = subprocess.Popen(['su', 'nmsadm', '-c', 'smtool -coldrestart ONRM_CS ARNEServer MAF NodeSynchServer -reason=planned -reasontext="deleting NRM"'], stdout=subprocess.PIPE).communicate()
if err:
    sys.exit('Starting ONRM, ARNE, MAF and NodeSYnchServer fails.')
run_progress('su nmsadm -c "smtool -p"')
print 'ONRM, ARNE, MAF and NodeSYnchServer has started'


'''8. Run as nmsadm and clear out the Seg CS DB'''
(out, err) = subprocess.Popen(['su', 'nmsadm', '-c', '/opt/ericsson/nms_umts_wranmom/bin/start_databases.sh -f'], stdout=subprocess.PIPE).communicate()
if not err:
    print 'the Seg CS DB has been cleaned'
else:
    sys.exit('the Seg CS DB cannot be cleaned')


''' 9. Online the Region and Seg CS
   10. Coldrestart all MCs'''
(out, err) = subprocess.Popen(['su', 'nmsadm', '-c', 'smtool -start'], stdout=subprocess.PIPE).communicate()
if err:
    sys.exit('Starting all services fails.')
run_progress('su nmsadm -c "smtool -p"')
print 'All services are online.'

'''11. Clear out LDAP'''
(out, err) = subprocess.Popen(['perl', './clean_ldap.pl'], stdout=subprocess.PIPE).communicate()
if err:
    sys.exit('LDAP is not cleared')

'''12. Check it is cleaned out - it should return nothing'''
(out, err) = subprocess.Popen(['perl', './clean_ldap.pl', '-list'], stdout=subprocess.PIPE).communicate()
if err or out:
    sys.exit('LDAP is not cleared')
else:
    print 'LDAP is cleared'
    
'''13. Delete the AUth info from TSS, Check if there is any first
targetAdmin -list NE_ACCESS | grep -v ALL_NE_GROUP

14. Then use tss_auth.sh to delete all info.
./tss_auth.sh

15. Check all info is deleted.
targetAdmin -list NE_ACCESS | grep -v ALL_NE_GROUP'''
f = open('temp', 'w')
proc1 = subprocess.Popen(["targetAdmin", "-list", "NE_ACCESS"], stdout=subprocess.PIPE)
proc2 = subprocess.Popen(["grep", "-v", "ALL_NE_GROUP"], stdin=proc1.stdout, stdout=subprocess.PIPE)
proc3 = subprocess.Popen(["grep", "-v", "TARGET:            TYPE:                     INFO:"], stdin=proc2.stdout, stdout=subprocess.PIPE)
(out, err) = proc3.communicate()
if err:
    sys.exit('cannot delete the AUth info from TSS')
auth_info = []
if out:
    f.write(out)
f.close()

(out, err) = subprocess.Popen(["targetAdmin", "-d", "-f", "temp"], stdout=subprocess.PIPE).communicate()
if err:
    sys.exit('cannot delete the AUth info from TSS')
else:
    os.remove('temp')
    print 'AUth info is deleted'

'''16. Run this cmd to check whats in the password server:
pwAdmin -l | grep -v SYSTEM | grep -v FTP | grep -v ONRM | grep -v SQL | grep -v LDAP | grep -v AOS | grep -v grep

17. Use the script below to delete all users from TSS, make sure that AOS users are not deleted.
./tss_password.sh

18. run this cmd to check whats in the password server:
pwAdmin -l | grep -v SYSTEM | grep -v FTP | grep -v ONRM | grep -v SQL | grep -v LDAP | grep -v AOS | grep -v grep | wc -l
'''
f = open('temp', 'w')
(out, err) = subprocess.Popen(['su', 'nmsadm', '-c', 'pwAdmin -l | grep -v SYSTEM | grep -v FTP | grep -v ONRM | grep -v SQL | grep -v LDAP | grep -v AOS | grep -v grep | grep -v egration'], stdout=subprocess.PIPE).communicate()
if err:
    sys.exit('cannot delete users')
else:
    f.write(out)
f.close()
(out, err) = subprocess.Popen(["pwAdmin", "-d", "-f", "temp"], stdout=subprocess.PIPE).communicate()
if err:
    sys.exit('cannot delete users')
else:
    os.remove('temp')
    print 'users are deleted'


'''
19. Now ONRM SEG TSS and LDAP are emptied and ready for import of new Network

20. In order to complete the procedure you now have to restor the FTP Services that were deleted. 
    To do this Import the necessary xmls files from the FTP SERVICES directory as described in the Prerequisite.'''
if not os.listdir('/var/opt/ericsson/arne/FTPServices/'):
    if not distutils.dir_util.copy_tree('/var/tmp/FTPServices_bk','/var/opt/ericsson/arne/FTPServices/'):
        sys.exit('restore FTP services failed!')


print 'SNAD cache is cleared'
