#!/bin/bash
vagrant ssh -- -C 'sudo service coldfusion restart'
read -rsp $'Press any key to continue...\n' -n 1 key
