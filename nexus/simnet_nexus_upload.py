'''
Created on Jan 29, 2015

@author: eaefhiq
'''

import re
import subprocess
class SimnetNexusRepoManager(object):
    '''
    classdocs
    '''

    invalid_lte_pattern = re.compile(r'[\w]+(?!.*_LTE\/)')
    invalid_wran_pattern = re.compile(r'[\w]+(?!.*_WRAN\/)')
    invalid_gran_pattern = re.compile(r'[\w]+(?!.*_GRAN\/)')
    invalid_core_pattern = re.compile(r'[\w]+(?!.*_CORE\/)')
    invalid_onetwork_pattern = re.compile(r'[\w]+(?!.*_ONETWORK\/)')
    invalid_with_version_pattern=re.compile('\d+\.\d+\.\d+')
    def __init__(self, nexus_host, nexus_port, nexus_protocol, nexus_simnet_root_path, nexus_username, nexus_password):
        '''
        Constructor
        '''
        self.nexus_host = nexus_host
        self.nexus_port = nexus_port
        self.nexus_protocol = nexus_protocol
        self.nexus_simnet_root_path = nexus_simnet_root_path
        self.nexus_username = nexus_username
        self.nexus_password = nexus_password
        self.authentication = self.nexus_username + ":" + self.nexus_password
        self.base_url = self.nexus_protocol + '://' + self.nexus_host + ':' + self.nexus_port + self.nexus_simnet_root_path
        
    
    
    
    def upload_file(self, upload_file, nexus_file_name):
        print(self.base_url + nexus_file_name)
        subprocess.Popen(["curl", "-k", "--upload-file", upload_file, "-u", self.authentication, "-v", self.base_url + nexus_file_name])
        
        

                    
                
    def upload_file_with_version(self, upload_file, nexus_dir, version, nexus_file_name):
            subprocess.Popen(["curl", "-k", "--upload-file", upload_file, "-u", self.authentication, "-v", 
                              self.base_url + '/' + 
                              nexus_dir + '/' + 
                              version + '/' + 
                              nexus_file_name])    
    
    

import argparse
import sys

# logging.warn('is when this event was logged.')

def check_arg(args=None):
    parser = argparse.ArgumentParser(description='Script to learn basic argparse')
    parser.add_argument('-H', '--host',
                        help='nexus host URL or IP address',
                        default='arm901-eiffel004.athtem.eei.ericsson.se')
    parser.add_argument('-p','--port',help='port number', default='8443')
    parser.add_argument('-P','--protocol', help='protocol',default='https')
    parser.add_argument('-R','--simnet_root', help='simnet root directory in nexus', default='/nexus/content/repositories/simnet/com/ericsson/simnet/')
    parser.add_argument('-u','--username', help='nexus username',default='simnet')
    parser.add_argument('-ps','--password',help='nexus password',default='simnet01')
    parser.add_argument('-upload','--upload',
                        help='''upload file 4 arguments are required 1. local file path for uploading 
                        2. nexus directory (name of the simulation)
                        3. simulation version
                        4. nexus name of the file''',nargs=4)

    
    results = parser.parse_args(args)
    return (results.host,results.port,results.protocol,results.simnet_root,results.username,results.password, 
            results.upload)



def clean_house(snrm):
    import logging
    logging.basicConfig(filename='/var/tmp/nexus_removed_invalid_links.log',format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p', filemode='a',level=logging.WARN)
    invalid_links=snrm.clean_house()
    if invalid_links:
        for link in invalid_links:
            logging.warn(link)
        print ('The nexus has been cleaned')
    else:
        print ('Nothing needs to be cleaned')
            
            

def clean_old_sims(clean_before):
    import logging
    logging.basicConfig(filename='/var/tmp/nexus_removed_invalid_links.log',format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p', filemode='a',level=logging.WARN)
    time_before=[int(n) for n in clean_before.split(',')]
    removed_link=snrm.clean_older_than(time_before[0], time_before[1], time_before[2], time_before[3],time_before[4])
    if len(removed_link)>1:
        print('\n')
       # [print (link) for link in removed_link]
    
    

if __name__ == '__main__':
    (nexus_host,
     nexus_port,
     nexus_protocol,
     nexus_simnet_root_path,
     nexus_username,
     nexus_password,
     upload,
#      upload_file,
#      nexus_dir,
#      version,
#      nexus_file_name
     )=check_arg(sys.argv[1:])
    
    snrm=SimnetNexusRepoManager(nexus_host=nexus_host,
                                nexus_port=nexus_port,
                                nexus_protocol=nexus_protocol,
                                nexus_simnet_root_path=nexus_simnet_root_path,
                                nexus_username=nexus_username,
                                nexus_password=nexus_password)
    
    
    if upload:
        snrm.upload_file_with_version(upload[0], upload[1], upload[2], upload[3])

        




