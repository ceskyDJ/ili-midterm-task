#!/bin/bash                                                                                                                                                                                                                           
                                                                                                                                                                                                                                      
# Log file for outputs from ran utils                                                                                                                                                                                                 
log_file="$0.log"                                                                                                                                                                                                                     
echo "" >$log_file                                                                                                                                                                                                                    
                                                                                                                                                                                                                                      
# Function for logging tasks titles (headers, resp.)                                                                                                                                                                                  
task_num=0                                                                                                                                                                                                                            
function log_title() {                                                                                                                                                                                                                
    (( task_num++ ))                                                                                                                                                                                                                  
    tput bold                                                                                                                                                                                                                         
    tput setaf 48                                                                                                                                                                                                                     
    echo -n "Task $task_num:" | sed 's/\( [0-9]:\)/ \1/'                                                                                                                                                                              
    tput sgr0                                                                                                                                                                                                                         
    tput setaf 48                                                                                                                                                                                                                     
    echo " $1"                                                                                                                                                                                                                        
    tput sgr0                                                                                                                                                                                                                         
}                                                                                                                                                                                                                                     

# Function for logging actions    
function log_action() {    
    echo -e "  > $1"    
}    

# Function for logging info (outputs from status commands)    
function log_info() {    
    tput bold    
    tput setaf 247    
    echo -e "      $1"    
    tput sgr0    
    tput setaf 253    
    cat | sed 's/^/      /'    
    tput sgr0    
}    

# Task 1: loop devices    
log_title "Create 4 loop devices"    

for(( i=0; i < 4; i++ )) do    
    log_action "Creating file for loop device $i..."    
    dd if=/dev/zero of=loop-dev-$i bs=200M count=1 >>$log_file 2>&1    

    log_action "Creating loop device $1..."    
    losetup loop$i ./loop-dev-$i >>$log_file 2>&1    
done

# Task 2: SW RAIDs
log_title "Create SW RAID 1 (dev 0 and 1) and RAID 0 (dev 2 and 3)"                                                                                                                                                                   
                                                                                                                                                                                                                                      
log_action "Creating RAID 1 on loop devices 0 and 1..."                                                                                                                                                                               
mdadm --create /dev/md0 --metadata=0 --level=mirror --raid-devices=2 /dev/loop0 /dev/loop1 >>$log_file 2>&1                                                                                                                           
                                                                                                                                                                                                                                      
log_action "Creating RAID 0 on loop devices 2 and 3..."                                                                                                                                                                               
mdadm --create /dev/md1 --metadata=0 --level=stripe --raid-devices=2 /dev/loop2 /dev/loop3 >>$log_file 2>&1                                                                                                                           
                                                                                                                                                                                                                                      
# Task 3: volume group                                                                                                                                                                                                                
log_title "Create volume group on top of RAID devs"                                                                                                                                                                                   
                                                                                                                                                                                                                                      
log_action "Creating volume group FIT_vg..."                                                                                                                                                                                          
vgcreate FIT_vg /dev/md{0,1} >>$log_file 2>&1                                                                                                                                                                                         
                                                                                                                                                                                                                                      
# Task 4: logical volumes                                                                                                                                                                                                             
log_title "Create 2 logical volumes in the volume group"                                                                                                                                                                              
                                                                                                                                                                                                                                      
for (( i=1; i <= 2; i++ )) do                                                                                                                                                                                                         
    log_action "Creating logical volume FIT_lv$i..."                                                                                                                                                                                  
    lvcreate FIT_vg -n FIT_lv$i -L100M >>$log_file 2>&1                                                                                                                                                                               
done                                                                                                                                                                                                                                  
                                                                                                                                                                                                                                      
# Task 5: EXT4 on 1st volume                                                                                                                                                                                                          
log_title "Create EXT4 filesystem on FIT_lv1"                                                                                                                                                                                         
                                                                                                                                                                                                                                      
log_action "Creating EXT4 filesystem..."                                                                                                                                                                                              
mkfs.ext4 /dev/FIT_vg/FIT_lv1 >>$log_file 2>&1                                                                                                                                                                                        
                                                                                                                                                                                                                                      
# Task 6: XFS on 2nd volume                                                                                                                                                                                                           
log_title "Create XFS filesystem on FIT_lv2"                                                                                                                                                                                          
                                                                                                                                                                                                                                      
log_action "Creating XFS filesystem..."                                                                                                                                                                                               
mkfs.xfs /dev/FIT_vg/FIT_lv2 >>$log_file 2>&1

# Task 7: mount volumes                                                                                                                                                                                                               
log_title "Mount FIT_lv1 and FIT_lv2 volumes"                                                                                                                                                                                         
                                                                                                                                                                                                                                      
for (( i=1; i <= 2; i++ )) do                                                                                                                                                                                                         
    log_action "Creating mount point /mnt/test$i..."                                                                                                                                                                                  
    mkdir /mnt/test$i >>$log_file 2>&1                                                                                                                                                                                                
                                                                                                                                                                                                                                      
    log_action "Mounting logical volume FIT_lv$i to /mnt/test$i..."                                                                                                                                                                   
    mount /dev/FIT_vg/FIT_lv$i /mnt/test$i >>$log_file 2>&1                                                                                                                                                                           
done                                                                                                                                                                                                                                  
                                                                                                                                                                                                                                      
# Task 8: resize 1st volume                                                                                                                                                                                                           
log_title "Resize FIT_lv1 to claim all available space"                                                                                                                                                                               
                                                                                                                                                                                                                                      
log_action "Resizing volume FIT_lv1 and its filesystem..."                                                                                                                                                                            
lvextend --resizefs -l +100%FREE /dev/FIT_vg/FIT_lv1 >>$log_file 2>&1                                                                                                                                                                 
                                                                                                                                                                                                                                      
df -h | log_info "Status after change:"                                                                                                                                                                                               
                                                                                                                                                                                                                                      
# Task 9: big file                                                                                                                                                                                                                    
log_title "Create 300 MB file /mnt/test1/big_file and its checksum"                                                                                                                                                                   
                                                                                                                                                                                                                                      
log_action "Creating /mnt/test1/big_file with data from /dev/urandom..."                                                                                                                                                              
dd if=/dev/urandom of=/mnt/test1/big_file bs=300M count=1 >>$log_file 2>&1                                                                                                                                                            
                                                                                                                                                                                                                                      
log_action "Counting checksum of /mnt/test1/big_file..."                                                                                                                                                                              
sha512sum /mnt/test1/big_file | grep -E "^[^ ]+" -o | log_info "SHA512 checksum:"                                                                                                                                                     
                                                                                                                                                                                                                                      
# Task 10: disk replacement                                                                                                                                                                                                           
log_title "Emulate faulty disk replacement"                                                                                                                                                                                           
                                                                                                                                                                                                                                      
log_action "Creating file for a new loop device..."                                                                                                                                                                                   
dd if=/dev/zero of=loop-dev-4 bs=200M count=1 >>$log_file 2>&1                                                                                                                                                                        
                                                                                                                                                                                                                                      
log_action "Creating loop device /dev/loop4..."                                                                                                                                                                                       
losetup loop4 ./loop-dev-4 >>$log_file 2>&1                                                                                                                                                                                           
                                                                                                                                                                                                                                      
log_action "Ejecting device /dev/loop0 from RAID1..."                                                                                                                                                                                 
mdadm --manage /dev/md0 --fail /dev/loop0 >>$log_file 2>&1                                                                                                                                                                            
mdadm --manage /dev/md0 --remove /dev/loop0 >>$log_file 2>&1                                                                                                                                                                          
                                                                                                                                                                                                                                      
log_action "Inserting device /dev/loop4 to RAID1..."                                                                                                                                                                                  
mdadm --manage /dev/md0 --add /dev/loop4 >>$log_file 2>&1                                                                                                                                                                             
                                                                                                                                                                                                                                      
sleep 5 # Recovery of RAID1 takes some time...                                                                                                                                                                                        
cat /proc/mdstat | log_info "State of RAID devices after changes:"
