# Deploy CPTC VMs (on each Proxmox node) 
1) `touch cptcvmslist.txt output.txt`. Add VM ids to `cptcvmslist.txt`
2) `nohup ./downloadcptcvms.sh > output.txt 2>&1 &`
