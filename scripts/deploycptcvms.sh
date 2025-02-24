#!/bin/bash

# parameters: cptc year, start_index
cptc_num=$1
vms_start_index=$2

# Read file line by line, add each ID to the vm_ids array
vm_ids=()
while read -r line; do 
  vm_ids+=("${line}")
done < cptcvmslist.txt # TODO: make parameter 

echo "VM IDs: ${vm_ids[@]}"

# Loop through each VM ID and download, unzip 
url_prefix="https://mirrors.rit.edu/cptc/cptc${cptc_num}/VMs/"
url_suffix=".vmdk.gz"

for vm_id_index in "${!vm_ids[@]}"
do
  vm_id="${vm_ids[vm_id_index]}"
  pve_vm_id=$((vm_id_index + vms_start_index))
  url="${url_prefix}${vm_id}${url_suffix}"

  echo "Downloading ${url}..."
  curl --output "${vm_id}.vmdk.gz" "${url}"

  echo "Unzipping ${vm_id}.vmdk.gz..."
  gunzip "${vm_id}.vmdk.gz" 

  echo "Converting ${vm_id}.vmdk to qcow2..."
  qemu-img convert -f vmdk -O qcow2 "${vm_id}.vmdk" "${vm_id}.qcow2"

  echo "Removing original VMDK file..."
  rm "${vm_id}.vmdk"

  echo "Creating new VM with ID ${pve_vm_id}..."
  qm create "${pve_vm_id}" --name "${pve_vm_id}" --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0

  echo "Importing disk into Proxmox local storage..."
  qm importdisk "${pve_vm_id}" "${vm_id}.qcow2" local --format qcow2

  echo "Removing temporary QCOW2 file..."
  rm "${vm_id}.qcow2"

  echo "Attaching imported disk to VM..."
  qm set "${pve_vm_id}" --scsi0 "local:${pve_vm_id}/vm-${pve_vm_id}-disk-0.qcow2"

  echo "Setting boot options for VM ${pve_vm_id}..."
  qm set "${pve_vm_id}" --scsihw virtio-scsi-pci --boot c --bootdisk scsi0
done

echo "All VMs have been processed successfully!"

