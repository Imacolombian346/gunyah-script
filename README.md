# gunyah-script
Backup and save and run script for the gunyah VM to make your life easier when running VMs.

notes: run the script as root, termux recommended to use the script, use this command:
```
chmod +x main.sh
su -c ./main.sh
```
i also recommend reading the guide for some context on what the script does as the script only setups the external env for the vm to work, you still have to setup some things on the vm to make things like networking work and to not boot to recovery mode, here's the tutorial for reference: https://github.com/polygraphene/gunyah-on-sd-guide

lastly i recommend using the option 4 as it will setup everything for you, and if the vm starts and stops the first time run it again it should start well
